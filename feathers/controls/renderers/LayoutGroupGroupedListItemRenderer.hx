/*
Feathers
Copyright 2012-2014 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.controls.renderers;
import feathers.controls.GroupedList;
import feathers.controls.LayoutGroup;
import feathers.skins.IStyleProvider;

import starling.events.Event;

/**
 * Based on <code>LayoutGroup</code>, this component is meant as a base
 * class for creating a custom item renderer for a <code>GroupedList</code>
 * component.
 *
 * <p>Sub-components may be created and added inside <code>initialize()</code>.
 * This is a good place to add event listeners and to set the layout.</p>
 *
 * <p>The <code>data</code> property may be parsed inside <code>commitData()</code>.
 * Use this function to change properties in your sub-components.</p>
 *
 * <p>Sub-components may be positioned manually, but a layout may be
 * provided as well. An <code>AnchorLayout</code> is recommended for fluid
 * layouts that can automatically adjust positions when the list resizes.
 * Create <code>AnchorLayoutData</code> objects to define the constraints.</p>
 *
 * @see feathers.controls.GroupedList
 */
class LayoutGroupGroupedListItemRenderer extends LayoutGroup implements IGroupedListItemRenderer
{
	/**
	 * The default <code>IStyleProvider</code> for all <code>LayoutGroupGroupedListItemRenderer</code>
	 * components.
	 *
	 * @default null
	 * @see feathers.core.FeathersControl#styleProvider
	 */
	public static var globalStyleProvider:IStyleProvider;

	/**
	 * Constructor.
	 */
	public function LayoutGroupGroupedListItemRenderer()
	{
		super();
	}

	/**
	 * @private
	 */
	override private function get_defaultStyleProvider():IStyleProvider
	{
		return LayoutGroupGroupedListItemRenderer.globalStyleProvider;
	}

	/**
	 * @private
	 */
	private var _groupIndex:Int = -1;

	/**
	 * @inheritDoc
	 */
	public function get_groupIndex():Int
	{
		return this._groupIndex;
	}

	/**
	 * @private
	 */
	public function set_groupIndex(value:Int):Void
	{
		this._groupIndex = value;
	}

	/**
	 * @private
	 */
	private var _itemIndex:Int = -1;

	/**
	 * @inheritDoc
	 */
	public function get_itemIndex():Int
	{
		return this._itemIndex;
	}

	/**
	 * @private
	 */
	public function set_itemIndex(value:Int):Void
	{
		this._itemIndex = value;
	}

	/**
	 * @private
	 */
	private var _layoutIndex:Int = -1;

	/**
	 * @inheritDoc
	 */
	public function get_layoutIndex():Int
	{
		return this._layoutIndex;
	}

	/**
	 * @private
	 */
	public function set_layoutIndex(value:Int):Void
	{
		this._layoutIndex = value;
	}

	/**
	 * @private
	 */
	private var _owner:GroupedList;

	/**
	 * @inheritDoc
	 */
	public function get_owner():GroupedList
	{
		return this._owner;
	}

	/**
	 * @private
	 */
	public function set_owner(value:GroupedList):Void
	{
		if(this._owner == value)
		{
			return;
		}
		this._owner = value;
		this.invalidate(INVALIDATION_FLAG_DATA);
	}

	/**
	 * @private
	 */
	private var _data:Object;

	/**
	 * @inheritDoc
	 */
	public function get_data():Object
	{
		return this._data;
	}

	/**
	 * @private
	 */
	public function set_data(value:Object):Void
	{
		if(this._data == value)
		{
			return;
		}
		this._data = value;
		this.invalidate(INVALIDATION_FLAG_DATA);
	}

	/**
	 * @private
	 */
	private var _isSelected:Bool;

	/**
	 * @inheritDoc
	 */
	public function get_isSelected():Bool
	{
		return this._isSelected;
	}

	/**
	 * @private
	 */
	public function set_isSelected(value:Bool):Void
	{
		if(this._isSelected == value)
		{
			return;
		}
		this._isSelected = value;
		this.invalidate(INVALIDATION_FLAG_SELECTED);
		this.dispatchEventWith(Event.CHANGE);
	}

	/**
	 * @private
	 */
	override public function dispose():Void
	{
		this.owner = null;
		super.dispose();
	}

	/**
	 * @private
	 */
	override private function draw():Void
	{
		var dataInvalid:Bool = this.isInvalid(INVALIDATION_FLAG_DATA);
		var scrollInvalid:Bool = this.isInvalid(INVALIDATION_FLAG_SCROLL);
		var sizeInvalid:Bool = this.isInvalid(INVALIDATION_FLAG_SIZE);
		var layoutInvalid:Bool = this.isInvalid(INVALIDATION_FLAG_LAYOUT);

		if(dataInvalid)
		{
			this.commitData();
		}

		if(scrollInvalid || sizeInvalid || layoutInvalid)
		{
			this._ignoreChildChanges = true;
			this.preLayout();
			this._ignoreChildChanges = false;
		}

		super.draw();

		if(scrollInvalid || sizeInvalid || layoutInvalid)
		{
			this._ignoreChildChanges = true;
			this.postLayout();
			this._ignoreChildChanges = false;
		}
	}

	/**
	 * Makes final changes to the layout before it updates the item
	 * renderer's children. If your layout requires changing the
	 * <code>layoutData</code> property on the item renderer's
	 * sub-components, override the <code>preLayout()</code> function to
	 * make those changes.
	 *
	 * <p>In subclasses, if you create properties that affect the layout,
	 * invalidate using <code>INVALIDATION_FLAG_LAYOUT</code> to trigger a
	 * call to the <code>preLayout()</code> function when the component
	 * validates.</p>
	 *
	 * <p>The final width and height of the item renderer are not yet known
	 * when this function is called. It is meant mainly for adjusting values
	 * used by fluid layouts, such as constraints or percentages. If you
	 * need io access the final width and height of the item renderer,
	 * override the <code>postLayout()</code> function instead.</p>
	 *
	 * @see #postLayout()
	 */
	private function preLayout():Void
	{

	}

	/**
	 * Called after the layout updates the item renderer's children. If any
	 * children are excluded from the layout, you can update them in the
	 * <code>postLayout()</code> function if you need to use the final width
	 * and height in any calculations.
	 *
	 * <p>In subclasses, if you create properties that affect the layout,
	 * invalidate using <code>INVALIDATION_FLAG_LAYOUT</code> to trigger a
	 * call to the <code>postLayout()</code> function when the component
	 * validates.</p>
	 *
	 * <p>To make changes to the layout before it updates the item
	 * renderer's children, override the <code>preLayout()</code> function
	 * instead.</p>
	 *
	 * @see #preLayout()
	 */
	private function postLayout():Void
	{

	}

	/**
	 * Updates the renderer to display the item's data. Override this
	 * function to pass data to sub-components and react to data changes.
	 *
	 * <p>Don't forget to handle the case where the data is <code>null</code>.</p>
	 */
	private function commitData():Void
	{

	}

}