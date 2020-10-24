package com.jcgurango.rehaxe.types;

typedef StateHook<T> = {
	public var value:T;
	public function setValue(newValue:T):Void;
}

typedef RendererContext = {
	public function hookEffect(callback:Void->(Void->Void), dependencies:Array<Any>):Void;
	public function hookState<T>(initializer:Void->T):StateHook<T>;
	public function hookMemo<T>(initializer:Void->T, dependencies:Array<Any>):T;
	public function hookContext<T>(type:String):T;
}
