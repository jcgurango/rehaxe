package com.jcgurango.rehaxe.types;

import com.jcgurango.rehaxe.MountedObject;

typedef BaseObject = {
	public var children:Array<BaseObjectRenderer>;
	public var props:Dynamic;
	public var ?provider:ContextProvider;
	public var ?ref:MountedObject->Void;
}
