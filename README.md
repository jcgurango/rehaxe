# Rehaxe
React-like renderer for haxe.

## Motivation
I initally set out to write React Native bindings for Cocos2D-x. I had given PIXI.js on a `<GLView />` before but the performance left a lot to be desired. After that I tried tacking on React Native to a Cocos2D-x C++ project. The performance was actually not too bad, hovered around 60 FPS, but the effort saved by being able to program in JS wasn't worth effort it would take to reimplement Cocos2D-x nodes as React elements. So finally I decided to write myself something that embodied the same philosophy as React, but not in JavaScript so this library was born.

## Usage
I've only used this with OpenFL so far. First, you need to create a "RenderManager". Here's one I wrote for utilizing OpenFL DisplayObjects with this renderer:

```haxe
package components;

import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.display.DisplayObjectContainer;
import com.jcgurango.rehaxe.RenderManager;

class FLRenderManager implements RenderManager {
  private var root: DisplayObjectContainer;

  public function new(root: DisplayObjectContainer) {
    this.root = root;
  }

  public function isIntrinsicElement(name: String) {
    return name == 'container' || name == 'square';
  }

  public function createElement(name: String): Any {
    if (name == 'container') {
      return new Sprite();
    } else if (name == 'square') {
      var square = new Sprite();
      square.graphics.beginFill(0x24AFC4);
      square.graphics.drawRect(-50, -50, 100, 100);
      return square;
    }

    return null;
  }

  public function addElementTo(element: Any, destination: Any) {
    var e: DisplayObject = element;
    var dest: DisplayObjectContainer = this.root;

    if (destination != null) {
      dest = destination;
    }

    dest.addChild(e);
  }

  public function removeElementFrom(element: Any, source: Any) {
    var e: DisplayObject = element;
    var src: DisplayObjectContainer = this.root;

    if (source != null) {
      src = source;
    }

    src.removeChild(e);
  }

  public function applyProps(element: Any, props: Dynamic) {
    var elem: DisplayObject = element;
    elem.x = props.x;
    elem.y = props.y;

    if (props.rotation != null) {
      elem.rotation = props.rotation / Math.PI * 180;
    }
  }
}
```

This sample RenderManager recognizes 2 "intrinsic" elements (i.e. elements that render to an actual object in OpenFL, similar to how intrinsic elements represent actual DOM elements in ReactDOM). A generic "container" under which you can add display objects as children, and a "square" element which is a blue square ripped directly out of the "DrawShapes" OpenFL sample. Once you have a RenderManager, you can use it in a renderer. Here's how this FLRenderManager is used:

```haxe
package;

import openfl.display.Sprite;
import components.FLRenderManager;
import com.jcgurango.rehaxe.Renderer;

class Main extends Sprite {
	public var renderer: Renderer;

	public function new() {
		super();
		this.renderer = new Renderer(new FLRenderManager(this));
	}
}
```

### Rendering
To start rendering with Rehaxe, you need to create some element generators. Generators are just functions which return a `com.jcgurango.rehaxe.types.BaseObjectRenderer`. Here's a class with a couple which I wrote using the `FLRenderManager` above.

```haxe
package;

import com.jcgurango.rehaxe.types.BaseObjectRenderer;

class Test {
	public static function container(props:{
		x:Float,
		y:Float,
	}, key:String, children:Array<BaseObjectRenderer>):BaseObjectRenderer {
		return {
			elementName: 'container',
			key: key,
			render: function(context) {
				return {
					children: children,
					props: props,
				};
			},
		};
	}

	public static function square(props:{
		x:Float,
		y:Float,
		?rotation:Float,
	}, key:String, children:Array<BaseObjectRenderer>):BaseObjectRenderer {
		return {
			elementName: 'square',
			key: key,
			render: function(context) {
				return {
					children: children,
					props: props,
				};
			},
		};
	}
}
```

As you can see, `BaseObjectRenderer` simply returns an elementName (which will be checked against the render manager), a "key" (which works the same way the "key" prop works in React), and a render method which is passed a context object. We'll come back to that. But given the functions above, we can use this code to render on every frame:

```haxe
package;

import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.events.Event;
import components.Test.*;
import components.FLRenderManager;
import com.jcgurango.rehaxe.Renderer;

class Main extends Sprite {
	public var renderer: Renderer;

	public function new() {
		super();
		this.renderer = new Renderer(new FLRenderManager(this));
		this.addEventListener(Event.ENTER_FRAME, this.onFrame);
	}

	public var start: Int = Std.int(Date.now().getTime());

	public function onFrame(e: Event) {
		this.stage.frameRate = 60;
		var time = Date.now().getTime() - start;

		renderer.update(
      container({
        x: this.stage.stageWidth / 2,
        y: this.stage.stageHeight / 2,
      }, null, [
        square({
          x: Math.cos(time / 16 / 180 * Math.PI) * 100,
          y: Math.sin(time / 16 / 180 * Math.PI) * 100,
        }, null, []),
        square({
          x: 0,
          y: 0,
          rotation: time / 32 / 180 * Math.PI,
        }, null, []),
        square({
          x: 0,
          y: 0,
        }, null, [])
      ])
    );
	}
}
```

As you can see, the syntax with the generators is somewhat similar to what React JSX would be transpiled to. We pass the props through to it, an optional key, and an array of children. This is all passed to the `Renderer.update()` function which will then go through the tree, diff the elements, and translate that into corresponding calls to the `RenderManager` (i.e. createElement, addElementTo, removeElementFrom, and applyProps).

### Effect Hooks
I mentioned earlier that a "context" is passed to the render method of `BaseObjectRenderer`. This context object can be used to execute hooks with dependencies. One of these hooks is the effect hook, similar to React's `useEffect`.

```haxe
public static function square(props:{
  x:Float,
  y:Float,
  ?rotation:Float,
}, key:String, children:Array<BaseObjectRenderer>):BaseObjectRenderer {
  return {
    elementName: 'square',
    key: key,
    render: function(context) {
      context.hookEffect(function () {
        // Perform something whenever props.x changes.

        return function () {
          // Perform any cleanup necessary.
        };
      }, [props.x]);

      return {
        children: children,
        props: props,
      };
    },
  };
}
```

It can also be used without dependencies as a component will mount/unmount type of hook.

```haxe
context.hookEffect(function () {
  // Perform something whenever props.x changes.

  return function () {
    // Perform any cleanup necessary.
  };
}, []);
```

### State Hooks
Another type of hook you have access to is the state hook. This consists of an "initializer" function, which will be called once when the component is first created. It will return a `com.jcgurango.rehaxe.types.StateHook<T>`.

```haxe
var stateValue = context.hookState(function () {
  return 0;
});

// stateValue.value is "Int"
// stateValue.setValue(1) will update the value.
```

### Memo Hooks
Memo hooks mimic React's "useMemo()" functionality. You can also technically use it as a "useCallback()" if you want to, so I didn't bother implementing a "hookCallback" function.

```haxe
var memo = context.hookMemo(function () {
  // This expression will only be re-evaluated if props.x changes.
  return {
    x: props.x,
    y: props.y,
  };
}, [props.x]);

// memo = {
//   x: Int,
//   y: Int,
// }
```

### Context Hooks
Finally, there's a similar system to React's contexts. You can provide a value to all children by returning a "provider" property in the render function.

```haxe
public static function container(props:{
  x:Float,
  y:Float,
}, key:String, children:Array<BaseObjectRenderer>):BaseObjectRenderer {
  return {
    elementName: 'container',
    key: key,
    render: function(context) {
      return {
        children: children,
        props: props,
        // All children will automatically be passed a context value for "parentPosition"
        provider: {
          type: 'parentPosition',
          value: {
            x: props.x,
            y: props.y,
          },
        },
      };
    },
  };
}
```

Which you can then use in a child component as such.

```haxe
public static function square(props:{
  x:Float,
  y:Float,
  ?rotation:Float,
}, key:String, children:Array<BaseObjectRenderer>):BaseObjectRenderer {
  return {
    elementName: 'square',
    key: key,
    render: function(context) {
      var parentPosition: { x: Int, y: Int } = context.hookContext('parentPosition');

      // parentPosition = { x: stageWidth / 2, y: stageHeight / 2 }

      return {
        children: children,
        props: props,
      };
    },
  };
}
```

## Future
I plan to build out other libraries that make use of this as I go along, but as I'll only really be using them for my own projects I'll probably mostly be maintaining this main one.