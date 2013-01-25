/* 
DISCLAIMER:

This SOFTWARE PRODUCT is provided by me "as is" and "with all faults." I make no representations or
warranties of any kind concerning the safety, suitability, lack of viruses, inaccuracies, typographical
errors, or other harmful components of this SOFTWARE PRODUCT. There are inherent dangers in the use of
any software, and you are solely responsible for determining whether this SOFTWARE PRODUCT is compatible 
with your equipment and other software installed on your equipment. You are also solely responsible for
the protection of your equipment and backup of your data, and I will not be liable for any damages you 
may suffer in connection with using, modifying, or distributing this SOFTWARE PRODUCT.

Your reuse is governed by the Creative Commons Attribution 3.0 License
Copyright (c) 2009 - 2010 Gilad Manor >> http://giladmanor.com 

to make this work you need to have the as3crypto package in your project.
get it at: http://code.google.com/p/as3crypto


*/


package wonderland.model.persistance
{
	import com.hurlant.crypto.Crypto;
	import com.hurlant.crypto.symmetric.ICipher;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;
	import flash.utils.CompressionAlgorithm;

	public class CryptoAsync extends EventDispatcher
	{
		private var _read:FileStream = new FileStream();
		private var _write:FileStream = new FileStream();
		private var _key:ByteArray = new ByteArray();
		
		private var _source:String;
		private var _destination:String;
		private var _aes:ICipher;
 		
 		//the cunck size can be calculated and measured, i didnt implement it.. 
 		private const eCHUNK:int = 16400; // -> the chunk size for encryption
 		private const dCHUNK:int = 16416; // -> the chunk size for decryption
 		private var cChunk:int = 0;
 		
 		private var _buffer:ByteArray;
 		private var _position:uint;
 		private var _result:ByteArray;
		
		public static const ENCRYPT:int = 0;
		public static const DECRYPT:int = 1;
		private var _action:int=0;
		
		private var _isFinnalized:Boolean;
				
		public function CryptoAsync(source:String, destination:String, key:String, action:int)
		{
			_key = stringToByteArray(key);
			_aes = Crypto.getCipher("aes-ecb", _key, Crypto.getPad("pkcs5"));
			_source = source;
			_destination = destination;
			_action = action;
			
			//its up to you if to call the initiation function from here:
			//getSet();
		}
		
		public function getSet():void{
			trace("setting: "+_source);
			var sourceFile:File = new File(_source);
			var destinationFile:File = new File(_destination);
			
			_write.open(destinationFile,FileMode.WRITE); 
			_read.open(sourceFile,FileMode.READ);
			
			_buffer = new ByteArray();
			_result = new ByteArray();
			_read.readBytes(_buffer, 0, _read.bytesAvailable);
			
			if(_action==DECRYPT){
				cChunk = dCHUNK;
			}else{
				_buffer.compress(CompressionAlgorithm.DEFLATE);
				cChunk=eCHUNK;
			} 
			_position = 0;
			_isFinnalized = false;
		}
		
		public function run(data:Object):Boolean{
			trace("processing: " +_source);
			//the heavy duty stuff happends here so each call is a single iteration on what would otherwise be a loop
			if((_buffer.length-_position)>cChunk){
				processChunk(_position,cChunk);
				_position += cChunk;
				var e:ProgressEvent = new ProgressEvent(ProgressEvent.PROGRESS,false,false,_position,_buffer.length);
				this.dispatchEvent(e);
				return true;
			}else if(!_isFinnalized){
				processChunk(_position,_buffer.length - _position);
				finnalize();
				this.dispatchEvent(new Event(Event.COMPLETE));
			}
			return false;
		}
		
		private function processChunk(position:uint,chunk:uint):void{
			var buffer:ByteArray = new ByteArray();
			buffer.writeBytes(_buffer,position,chunk);
			 if(_action==ENCRYPT){
		    	_aes.encrypt(buffer);
		    }else{
		    	_aes.decrypt(buffer);
		    } 
		    _result.writeBytes(buffer);
		}
		
		private function finnalize():void{
			if(_action==DECRYPT){
				_result.uncompress(CompressionAlgorithm.DEFLATE);
			}else{
			} 
			
			//flush result to output file
			_write.writeBytes(_result);
			
			_read.close();
			_write.close();
			_isFinnalized = true;
			trace("finnalized: "+_source);
		}
				
		private static function stringToByteArray(data:String):ByteArray{
			var res:ByteArray = new ByteArray();
			res.writeUTFBytes(data);
			return res;
		}
		
	}
}