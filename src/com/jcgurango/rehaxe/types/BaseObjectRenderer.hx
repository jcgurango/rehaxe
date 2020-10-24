package com.jcgurango.rehaxe.types;

typedef BaseObjectRenderer = {
	public var elementName:String;
	public var key:String;
	public function render(renderer:RendererContext):BaseObject;
}
