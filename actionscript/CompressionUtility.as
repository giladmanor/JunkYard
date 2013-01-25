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

*/

package wonderland.control.Util
{
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;
	import flash.utils.CompressionAlgorithm;
	
	public class CompressionUtility
	{
		private static const CHILDREN:String = "children";
		private static const NAME:String = "name";
		private static const DATA:String = "data";
		
		public function CompressionUtility()
		{
		}
		
		public static function compress(source:String, destination:String, fileName:String=null):void{
			var src:File = new File(source);
			var data:ByteArray = new ByteArray;
			data.writeObject(gather(src));
			data.compress(CompressionAlgorithm.DEFLATE);
			if(fileName==null){
				fileName = src.name+".def"
			}
			
			var res:File = new File(destination+File.separator+fileName);
			var resStream:FileStream = new FileStream();
			resStream.open(res,FileMode.WRITE);
			resStream.writeBytes(data,0,data.length);
			resStream.close();
		}
		
		private static function gather(source:File):Object{
			var desc:Object = new Object();
			desc[NAME] = source.name;
			if(source.isDirectory){
				var children:Array = new Array();
				for each(var file:File in source.getDirectoryListing()){
					children.push(gather(file));
				}
				desc[CHILDREN] = children;
			}else{
				var data:ByteArray = new ByteArray();
				var fs:FileStream = new FileStream();
				fs.open(source,FileMode.READ);
				fs.readBytes(data,0,fs.bytesAvailable);
				desc[DATA] = data;
			}
			return desc;
		}
		
		public static function decompress(source:String, destination:String):void{
			var src:File = new File(source);
			var inStream:FileStream = new FileStream();
			inStream.open(src,FileMode.READ);
			var ba:ByteArray = new ByteArray();
			inStream.readBytes(ba,0,inStream.bytesAvailable);
			ba.position=0;
			ba.uncompress(CompressionAlgorithm.DEFLATE);
			var data:Object = ba.readObject();
			distribute(data,destination);
		}
		
		private static function distribute(data:Object, dest:String):void{
			if(data.hasOwnProperty(CHILDREN)){
				var newDest:String = dest+File.separator + data[NAME];
				var a:Array = data[CHILDREN] as Array;
				for each (var o:Object in a){
					distribute(o,newDest);
				}
			}else{
				var fName:String = data[NAME];
				var file:File = new File(dest+File.separator+fName);
				var resStream:FileStream = new FileStream();
				resStream.open(file,FileMode.WRITE);
				var d:ByteArray = data[DATA] as ByteArray;
				resStream.writeBytes(d,0,d.bytesAvailable);
				resStream.close();
			}
		}
	}
}