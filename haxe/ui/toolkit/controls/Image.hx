package haxe.ui.toolkit.controls;

import haxe.Http;
import haxe.io.Bytes;
import haxe.ui.toolkit.core.Component;
import haxe.ui.toolkit.core.interfaces.IClonable;
import haxe.ui.toolkit.core.interfaces.InvalidationFlag;
import haxe.ui.toolkit.resources.ResourceManager;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Loader;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.net.URLLoader;
import openfl.net.URLLoaderDataFormat;
import openfl.net.URLRequest;

#if yagp
import com.yagp.GifDecoder;
import com.yagp.Gif;
import com.yagp.GifPlayer;
import com.yagp.GifPlayerWrapper;
import com.yagp.GifRenderer;
#end

#if svg
import format.SVG;
#end

/**
 General purpose image control
 **/
class Image extends Component implements IClonable<Image> {
	private var _bmp:Bitmap;
	private var _resource:Dynamic;
	private var _stretch:Bool;
	private var _autoDisposeBitmapData:Bool = false;
	
	#if yagp
	private var _gifWrapper:GifPlayerWrapper;
	#end
	
	#if svg
	private var _svgSprite:Sprite;
	#end
	
	public function new() {
		super();
		autoSize = true;
	}
	
	
	//******************************************************************************************
	// Overrides
	//******************************************************************************************
	private override function initialize():Void {
		super.initialize();
		updateContent();
	}
	
	/**
	 Destroy the image and free the resources (will be called by the framework automatically)
	 **/
	public override function dispose():Void {
		disposeContent();
		super.dispose();
	}
	
	private function disposeContent():Void {
		if (_bmp != null) {
			if (_autoDisposeBitmapData == true) {
				_bmp.bitmapData.dispose();
			}
			sprite.removeChild(_bmp);
			_bmp = null;
		}
		
		#if yagp
		if (_gifWrapper != null && sprite.contains(_gifWrapper)) {
			_gifWrapper.dispose();
			sprite.removeChild(_gifWrapper);
			_gifWrapper = null;
		}
		#end
		
		#if svg
		if (_svgSprite != null && sprite.contains(_svgSprite)) {
			sprite.removeChild(_svgSprite);
			_svgSprite = null;
		}
		#end
	}
	
	public override function invalidate(type:Int = InvalidationFlag.ALL, recursive:Bool = false):Void {
		super.invalidate(type, recursive);
		
		if (type & InvalidationFlag.SIZE == InvalidationFlag.SIZE) {
			updateContent();
		}
	}
	
	private override function get_value():Dynamic {
		return resource;
	}
	
	private override function set_value(newValue:Dynamic):Dynamic {
		resource = newValue;
		return newValue;
	}
	
	//******************************************************************************************
	// Methods/props
	//******************************************************************************************
	/**
	 The resource asset for this image: eg `assets/myimage.jpeg`
	 **/
	@:clonable
	public var resource(get, set):Dynamic;
	@:clonable
	public var stretch(get, set):Bool;
	@:clonable
	public var autoDisposeBitmapData(get, set):Bool;
	
	private function get_resource():Dynamic {
		return _resource;
	}
	
	private function set_resource(value:Dynamic):Dynamic {
		disposeContent();
		
		if (Std.is(value, String)) {
			if (StringTools.endsWith(value, ".gif")) {
				#if yagp
					loadGif(value, function(gif) {
						updateGif(gif);
					});
				#else
					trace("YAGP lib not found for .gif decoding");
				#end
			} else if (StringTools.endsWith(value, ".svg")) {
				#if svg
					loadSvg(value, function(svg) {
						updateSvg(svg);
					});
				#else
					trace("SVG lib not found for .svg decoding");
				#end
			} else {
				loadBitmap(value, function(bmpData) {
					updateBitmap(bmpData);
				});
			}
		} else if (Std.is(value, Bitmap)) {
			updateBitmap(cast(value, Bitmap).bitmapData);
		} else if (Std.is(value, BitmapData)) {
			updateBitmap(cast(value, BitmapData));
		}
		
		_resource = value;
		return value;
	}
	
	#if yagp
	private function loadGif(res:String, callback:Gif->Void):Void {
		if (StringTools.startsWith(res, "http://")) {
			var l:URLLoader = new URLLoader(); 
			l.dataFormat = URLLoaderDataFormat.BINARY;
			l.load(new URLRequest(res)); 
			l.addEventListener(Event.COMPLETE, function(dyn) { 
				callback(GifDecoder.parseByteArray(l.data));
			});
		} else {
			callback(GifDecoder.parseByteArray(ResourceManager.instance.getBytes(res)));
		}
	}
	
	private function updateGif(gif:Gif):Void {
		var player:GifPlayer = new GifPlayer(gif);
		_gifWrapper = new GifPlayerWrapper(player);
		updateContent();
	}
	#end
	
	#if svg
	private function loadSvg(res:String, callback:SVG->Void):Void {
		if (StringTools.startsWith(res, "http://")) {
			var l:URLLoader = new URLLoader(); 
			l.dataFormat = URLLoaderDataFormat.TEXT;
			l.load(new URLRequest(res)); 
			l.addEventListener(Event.COMPLETE, function(dyn) { 
				callback(new SVG(l.data));
			});
		} else {
			callback(ResourceManager.instance.getSVG(res));
		}
	}
	
	private function updateSvg(svg:SVG):Void {
		_svgSprite = new Sprite();
		svg.render(_svgSprite.graphics);
		_svgSprite.width = svg.data.width;
		_svgSprite.height = svg.data.height;
		updateContent();
	}
	#end
	
	private function loadBitmap(res:String, callback:BitmapData->Void):Void {
		if (StringTools.startsWith(res, "http://")) {
			#if flash
				var l:Loader = new Loader(); 
				l.load(new URLRequest(res)); 
				l.contentLoaderInfo.addEventListener(Event.INIT, function(dyn) { 
					var bmp:Bitmap = cast(l.content, Bitmap);
					var bmpData:BitmapData = new BitmapData(cast bmp.width, cast bmp.height, true, 0);
					bmpData.draw(bmp.bitmapData);
					callback(bmpData);
				});
			#else
				var r:Http = new Http(res);
				r.onData = function(imageData) {
					callback(BitmapData.loadFromHaxeBytes(Bytes.ofString(imageData)));
				}
				r.request();
			#end
		} else {
			callback(ResourceManager.instance.getBitmapData(res));
		}
	}
	
	private function updateBitmap(bmpData:BitmapData):Void {
		_bmp = new Bitmap(bmpData);
		updateContent();
	}
	
	private function updateContent():Void {
		#if yagp
		if (_gifWrapper != null) {
			if (sprite.contains(_gifWrapper) == false) {
				sprite.addChild(_gifWrapper);
			}
			if (ready) {
				if (autoSize == true) {
					this.width = _gifWrapper.width;
					this.height = _gifWrapper.height;
				} else if (_stretch == true) {
					_gifWrapper.width = width;
					_gifWrapper.height = height;
				}
			}
		}
		#end

		#if svg
		if (_svgSprite != null) {
			if (sprite.contains(_svgSprite) == false) {
				sprite.addChild(_svgSprite);
			}
			if (ready) {
				if (autoSize == true) {
					this.width = _svgSprite.width;
					this.height = _svgSprite.height;
				} else if (_stretch == true) {
					_svgSprite.width = width;
					_svgSprite.height = height;
				}
			}
		}
		#end
		
		if (_bmp != null) {
			if (sprite.contains(_bmp) == false) {
				sprite.addChild(_bmp);
			}
			if (ready) {
				if (autoSize == true) {
					this.width = _bmp.bitmapData.width;
					this.height = _bmp.bitmapData.height;
				} else if (_stretch == true) {
					_bmp.width = width;
					_bmp.height = height;
				}
			}
		}
	}
	
	private function get_stretch():Bool {
		return _stretch;
	}
	
	private function set_stretch(value:Bool):Bool {
		if (_stretch == value) {
			return value;
		}
		_autoSize = !value;
		_stretch = value;
		invalidate(InvalidationFlag.SIZE);
		return value;
	}
	
	private function get_autoDisposeBitmapData():Bool {
		return _autoDisposeBitmapData;
	}
	
	private function set_autoDisposeBitmapData(value:Bool):Bool {
		_autoDisposeBitmapData = value;
		return value;
	}
}