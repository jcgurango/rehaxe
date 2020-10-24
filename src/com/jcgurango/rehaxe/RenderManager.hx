package com.jcgurango.rehaxe;

import com.jcgurango.rehaxe.types.BaseObjectRenderer;
import com.jcgurango.rehaxe.types.BaseObject;

interface RenderManager {
  public function isIntrinsicElement(name: String): Bool;
  public function createElement(name: String): Any;
  public function addElementTo(element: Any, destination: Any): Void;
  public function removeElementFrom(element: Any, source: Any): Void;
  public function applyProps(element: Any, definition: BaseObjectRenderer, rendered: BaseObject, props: Dynamic): Void;
}
