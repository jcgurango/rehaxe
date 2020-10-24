package com.jcgurango.rehaxe;

import com.jcgurango.rehaxe.types.BaseObjectRenderer;

class Renderer {
	private var mountedPaths:Map<String, MountedObject>;
	private var current:BaseObjectRenderer;
	private var isDirty:Bool;
	private var renderManager:RenderManager;

	public function new(renderManager: RenderManager) {
		this.mountedPaths = new Map<String, MountedObject>();
		this.renderManager = renderManager;
		this.current = null;
	}

	private function compareDependencies(a:Array<Any>, b:Array<Any>) {
		for (i in 0...a.length) {
			if (a[i] != b[i]) {
				return true;
			}
		}

		return false;
	}

	public function traverse(parentPath:String, index:Int, object:BaseObjectRenderer, parent: Any, newMountedPaths:Map<String, MountedObject>,
			contextVariables:Map<String, Any>) {
		var path = parentPath + '.' + Std.string(index) + '[' + object.elementName + ']';

		if (object.key != null) {
			path += '[' + object.key + ']';
		}

		// Mount this object if it's not already mounted.
		var mountedObject = this.mountedPaths[path];

		if (mountedObject == null
			|| mountedObject.definition.elementName != object.elementName
			|| mountedObject.definition.key != object.key) {
			if (mountedObject != null) {
				mountedObject.unmount();
			}

			newMountedPaths[path] = new MountedObject(object, this.renderManager);
			mountedObject = newMountedPaths[path];
		}

		newMountedPaths[path] = mountedObject;

		var effectHookIndex = 0;
		var stateHookIndex = 0;
		var memoHookIndex = 0;

		var rendered = object.render({
			hookEffect: function(callback, dependencies) {
				if (effectHookIndex >= mountedObject.effectHookDependencies.length
					|| compareDependencies(mountedObject.effectHookDependencies[effectHookIndex], dependencies)) {
					if (effectHookIndex < mountedObject.effectHookCleanupFunctions.length) {
						mountedObject.effectHookCleanupFunctions[effectHookIndex]();
					}

					var unmounter = callback();

					if (effectHookIndex >= mountedObject.effectHookDependencies.length) {
						mountedObject.effectHookDependencies.push(dependencies);
						mountedObject.effectHookCleanupFunctions.push(unmounter);
					} else {
						mountedObject.effectHookDependencies[effectHookIndex] = dependencies;
						mountedObject.effectHookCleanupFunctions[effectHookIndex] = unmounter;
					}
				}

				effectHookIndex++;
			},
			hookState: function(generator) {
				var currentIndex = stateHookIndex;
				stateHookIndex++;

				if (stateHookIndex >= mountedObject.state.length) {
					mountedObject.state.push(generator());
				}

				return {
					value: mountedObject.state[currentIndex],
					setValue: function(value) {
						mountedObject.state[currentIndex] = value;
						this.isDirty = true;
					},
				};
			},
			hookContext: function(type) {
				return contextVariables.get(type);
			},
			hookMemo: function(initializer, dependencies) {
				if (memoHookIndex >= mountedObject.memoHookDependencies.length
					|| compareDependencies(mountedObject.memoHookDependencies[memoHookIndex], dependencies)) {
					if (memoHookIndex < mountedObject.effectHookCleanupFunctions.length) {
						mountedObject.effectHookCleanupFunctions[effectHookIndex]();
					}

					var value = initializer();

					if (memoHookIndex >= mountedObject.memoHookDependencies.length) {
						mountedObject.memoHookDependencies.push(dependencies);
						mountedObject.memoHookValues.push(value);
					} else {
						mountedObject.memoHookDependencies[memoHookIndex] = dependencies;
						mountedObject.memoHookValues[memoHookIndex] = value;
					}
				}

				return mountedObject.memoHookValues[memoHookIndex++];
			},
		});

		mountedObject.realParent = parent;

		if (!mountedObject.mounted) {
			mountedObject.mount();

			if (rendered.ref != null) {
				rendered.ref(mountedObject);
			}
		}

		mountedObject.updateProps(object, rendered, rendered.props);

		var nextParent = parent;

		if (mountedObject.realObject != null) {
			nextParent = mountedObject.realObject;
		}

		// Provide contexts to the child components.
		var newContextVariables = contextVariables;

		if (rendered.provider != null) {
			newContextVariables = newContextVariables.copy();
			newContextVariables[rendered.provider.type] = rendered.provider.value;
		}

		var childIndex = 0;

		for (child in rendered.children) {
			this.traverse(path, childIndex++, child, nextParent, newMountedPaths, newContextVariables);
		}
	}

	public function update(newObject:BaseObjectRenderer):Bool {
		this.isDirty = false;
		var newMountedPaths = new Map<String, MountedObject>();

		// Traverse through the tree.
		this.traverse('$', 0, newObject, null, newMountedPaths, new Map<String, Any>());

		// Unmount any keys that no longer exist.
		for (path in this.mountedPaths.keys()) {
			if (!newMountedPaths.exists(path)) {
				this.mountedPaths[path].unmount();
				this.mountedPaths.remove(path);
			}
		}

		// Update the mounted paths.
		this.mountedPaths = newMountedPaths;

		return this.isDirty;
	}
}
