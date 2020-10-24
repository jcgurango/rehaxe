package com.jcgurango.rehaxe;

import com.jcgurango.rehaxe.types.BaseObjectRenderer;

class MountedObject {
	public var definition:BaseObjectRenderer;
	public var realObject:Any;
	public var realParent:Any;
	public var mounted:Bool;
	public var effectHookDependencies:Array<Array<Any>>;
	public var effectHookCleanupFunctions:Array<Void->Void>;
	public var memoHookDependencies:Array<Array<Any>>;
	public var memoHookValues:Array<Any>;
	public var state:Array<Any>;
	private var renderManager: RenderManager;

	public function new(definition:BaseObjectRenderer, renderManager: RenderManager) {
		this.definition = definition;
		this.mounted = false;
		this.effectHookDependencies = new Array<Array<Any>>();
		this.effectHookCleanupFunctions = new Array<Void->Void>();
		this.memoHookDependencies = new Array<Array<Any>>();
		this.memoHookValues = new Array<Any>();
		this.state = new Array<Any>();
		this.renderManager = renderManager;
	}

	public function mount() {
		if (this.renderManager.isIntrinsicElement(this.definition.elementName)) {
			this.realObject = this.renderManager.createElement(this.definition.elementName);
			this.renderManager.addElementTo(this.realObject, this.realParent);
		}

		this.mounted = true;
	}

	public function unmount() {
		for (func in this.effectHookCleanupFunctions) {
			func();
		}

		this.renderManager.removeElementFrom(this.realObject, this.realParent);
		this.mounted = false;
	}

	public function updateProps(props:Dynamic) {
		if (this.realObject != null) {
			this.renderManager.applyProps(this.realObject, props);
		}
	}
}
