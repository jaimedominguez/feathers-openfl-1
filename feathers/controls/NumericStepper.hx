/*
Feathers
Copyright 2012-2014 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.controls;
import feathers.core.FeathersControl;
import feathers.core.IFocusDisplayObject;
import feathers.core.PropertyProxy;
import feathers.events.ExclusiveTouch;
import feathers.events.FeathersEventType;
import feathers.skins.IStyleProvider;
import feathers.utils.math.clamp;
import feathers.utils.math.roundToNearest;
import feathers.utils.math.roundToPrecision;

import flash.events.TimerEvent;
import flash.ui.Keyboard;
import flash.utils.Timer;

import starling.display.DisplayObject;
import starling.events.Event;
import starling.events.KeyboardEvent;
import starling.events.Touch;
import starling.events.TouchEvent;
import starling.events.TouchPhase;

/**
 * Dispatched when the stepper's value changes.
 *
 * <p>The properties of the event object have the following values:</p>
 * <table class="innertable">
 * <tr><th>Property</th><th>Value</th></tr>
 * <tr><td><code>bubbles</code></td><td>false</td></tr>
 * <tr><td><code>currentTarget</code></td><td>The Object that defines the
 *   event listener that handles the event. For example, if you use
 *   <code>myButton.addEventListener()</code> to register an event listener,
 *   myButton is the value of the <code>currentTarget</code>.</td></tr>
 * <tr><td><code>data</code></td><td>null</td></tr>
 * <tr><td><code>target</code></td><td>The Object that dispatched the event;
 *   it is not always the Object listening for the event. Use the
 *   <code>currentTarget</code> property to always access the Object
 *   listening for the event.</td></tr>
 * </table>
 *
 * @eventType starling.events.Event.CHANGE
 */
[Event(name="change",type="starling.events.Event")]

/**
 * Select a value between a minimum and a maximum by using increment and
 * decrement buttons or typing in a value in a text input.
 *
 * <p>The following example sets the stepper's values and listens for when
 * when the value changes:</p>
 *
 * <listing version="3.0">
 * var stepper:NumericStepper = new NumericStepper();
 * stepper.minimum = 0;
 * stepper.maximum = 100;
 * stepper.step = 1;
 * stepper.value = 12;
 * stepper.addEventListener( Event.CHANGE, stepper_changeHandler );
 * this.addChild( stepper );</listing>
 *
 * @see http://wiki.starling-framework.org/feathers/numeric-stepper
 */
class NumericStepper extends FeathersControl implements IRange, IFocusDisplayObject
{
	/**
	 * @private
	 */
	inline private static var INVALIDATION_FLAG_DECREMENT_BUTTON_FACTORY:String = "decrementButtonFactory";

	/**
	 * @private
	 */
	inline private static var INVALIDATION_FLAG_INCREMENT_BUTTON_FACTORY:String = "incrementButtonFactory";

	/**
	 * @private
	 */
	inline private static var INVALIDATION_FLAG_TEXT_INPUT_FACTORY:String = "textInputFactory";

	/**
	 * The default value added to the <code>styleNameList</code> of the decrement
	 * button.
	 *
	 * @see feathers.core.FeathersControl#styleNameList
	 */
	inline public static var DEFAULT_CHILD_NAME_DECREMENT_BUTTON:String = "feathers-numeric-stepper-decrement-button";

	/**
	 * The default value added to the <code>styleNameList</code> of the increment
	 * button.
	 *
	 * @see feathers.core.FeathersControl#styleNameList
	 */
	inline public static var DEFAULT_CHILD_NAME_INCREMENT_BUTTON:String = "feathers-numeric-stepper-increment-button";

	/**
	 * The default value added to the <code>styleNameList</code> of the text
	 * input.
	 *
	 * @see feathers.core.FeathersControl#styleNameList
	 */
	inline public static var DEFAULT_CHILD_NAME_TEXT_INPUT:String = "feathers-numeric-stepper-text-input";

	/**
	 * The decrement button will be placed on the left side of the text
	 * input and the increment button will be placed on the right side of
	 * the text input.
	 *
	 * @see #buttonLayoutMode
	 */
	inline public static var BUTTON_LAYOUT_MODE_SPLIT_HORIZONTAL:String = "splitHorizontal";

	/**
	 * The decrement button will be placed below the text input and the
	 * increment button will be placed above the text input.
	 *
	 * @see #buttonLayoutMode
	 */
	inline public static var BUTTON_LAYOUT_MODE_SPLIT_VERTICAL:String = "splitVertical";

	/**
	 * Both the decrement and increment button will be placed on the right
	 * side of the text input. The increment button will be above the
	 * decrement button.
	 *
	 * @see #buttonLayoutMode
	 */
	inline public static var BUTTON_LAYOUT_MODE_RIGHT_SIDE_VERTICAL:String = "rightSideVertical";

	/**
	 * The default <code>IStyleProvider</code> for all <code>NumericStepper</code>
	 * components.
	 *
	 * @default null
	 * @see feathers.core.FeathersControl#styleProvider
	 */
	public static var globalStyleProvider:IStyleProvider;

	/**
	 * @private
	 */
	private static function defaultDecrementButtonFactory():Button
	{
		return new Button();
	}

	/**
	 * @private
	 */
	private static function defaultIncrementButtonFactory():Button
	{
		return new Button();
	}

	/**
	 * @private
	 */
	private static function defaultTextInputFactory():TextInput
	{
		return new TextInput();
	}

	/**
	 * Constructor.
	 */
	public function NumericStepper()
	{
		super();
		this.addEventListener(Event.REMOVED_FROM_STAGE, numericStepper_removedFromStageHandler);
	}

	/**
	 * The value added to the <code>styleNameList</code> of the decrement button. This
	 * variable is <code>private</code> so that sub-classes can customize
	 * the decrement button name in their constructors instead of using the default
	 * name defined by <code>DEFAULT_CHILD_NAME_DECREMENT_BUTTON</code>.
	 *
	 * <p>To customize the decrement button name without subclassing, see
	 * <code>customDecrementButtonName</code>.</p>
	 *
	 * @see #customDecrementButtonName
	 * @see feathers.core.FeathersControl#styleNameList
	 */
	private var decrementButtonName:String = DEFAULT_CHILD_NAME_DECREMENT_BUTTON;

	/**
	 * The value added to the <code>styleNameList</code> of the increment button. This
	 * variable is <code>private</code> so that sub-classes can customize
	 * the increment button name in their constructors instead of using the default
	 * name defined by <code>DEFAULT_CHILD_NAME_INCREMENT_BUTTON</code>.
	 *
	 * <p>To customize the increment button name without subclassing, see
	 * <code>customIncrementButtonName</code>.</p>
	 *
	 * @see #customIncrementButtonName
	 * @see feathers.core.FeathersControl#styleNameList
	 */
	private var incrementButtonName:String = DEFAULT_CHILD_NAME_INCREMENT_BUTTON;

	/**
	 * The value added to the <code>styleNameList</code> of the text input. This
	 * variable is <code>private</code> so that sub-classes can customize
	 * the text input name in their constructors instead of using the default
	 * name defined by <code>DEFAULT_CHILD_NAME_TEXT_INPUT</code>.
	 *
	 * <p>To customize the text input name without subclassing, see
	 * <code>customTextInputName</code>.</p>
	 *
	 * @see #customTextInputName
	 * @see feathers.core.FeathersControl#styleNameList
	 */
	private var textInputName:String = DEFAULT_CHILD_NAME_TEXT_INPUT;

	/**
	 * The decrement button sub-component.
	 *
	 * <p>For internal use in subclasses.</p>
	 *
	 * @see #createDecrementButton()
	 */
	private var decrementButton:Button;

	/**
	 * The increment button sub-component.
	 *
	 * <p>For internal use in subclasses.</p>
	 *
	 * @see #createIncrementButton()
	 */
	private var incrementButton:Button;

	/**
	 * The text input sub-component.
	 *
	 * <p>For internal use in subclasses.</p>
	 *
	 * @see #createTextInput()
	 */
	private var textInput:TextInput;

	/**
	 * @private
	 */
	private var touchPointID:int = -1;

	/**
	 * @private
	 */
	override private function get defaultStyleProvider():IStyleProvider
	{
		return NumericStepper.globalStyleProvider;
	}

	/**
	 * @private
	 */
	private var _value:Number = 0;

	/**
	 * The value of the numeric stepper, between the minimum and maximum.
	 *
	 * <p>In the following example, the value is changed to 12:</p>
	 *
	 * <listing version="3.0">
	 * stepper.minimum = 0;
	 * stepper.maximum = 100;
	 * stepper.step = 1;
	 * stepper.value = 12;</listing>
	 *
	 * @default 0
	 *
	 * @see #minimum
	 * @see #maximum
	 * @see #step
	 * @see #event:change
	 */
	public function get value():Number
	{
		return this._value;
	}

	/**
	 * @private
	 */
	public function set value(newValue:Number):Void
	{
		if(this._step != 0 && newValue != this._maximum && newValue != this._minimum)
		{
			//roundToPrecision helps us to avoid numbers like 1.00000000000000001
			//caused by the inaccuracies of floating point math.
			newValue = roundToPrecision(roundToNearest(newValue - this._minimum, this._step) + this._minimum, 10);
		}
		newValue = clamp(newValue, this._minimum, this._maximum);
		if(this._value == newValue)
		{
			return;
		}
		this._value = newValue;
		this.invalidate(INVALIDATION_FLAG_DATA);
		this.dispatchEventWith(Event.CHANGE);
	}

	/**
	 * @private
	 */
	private var _minimum:Number = 0;

	/**
	 * The numeric stepper's value will not go lower than the minimum.
	 *
	 * <p>In the following example, the minimum is changed to 0:</p>
	 *
	 * <listing version="3.0">
	 * stepper.minimum = 0;
	 * stepper.maximum = 100;
	 * stepper.step = 1;
	 * stepper.value = 12;</listing>
	 *
	 * @default 0
	 *
	 * @see #value
	 * @see #maximum
	 * @see #step
	 */
	public function get minimum():Number
	{
		return this._minimum;
	}

	/**
	 * @private
	 */
	public function set minimum(value:Number):Void
	{
		if(this._minimum == value)
		{
			return;
		}
		this._minimum = value;
		this.invalidate(INVALIDATION_FLAG_DATA);
	}

	/**
	 * @private
	 */
	private var _maximum:Number = 0;

	/**
	 * The numeric stepper's value will not go higher than the maximum.
	 *
	 * <p>In the following example, the maximum is changed to 100:</p>
	 *
	 * <listing version="3.0">
	 * stepper.minimum = 0;
	 * stepper.maximum = 100;
	 * stepper.step = 1;
	 * stepper.value = 12;</listing>
	 *
	 * @default 0
	 *
	 * @see #value
	 * @see #minimum
	 * @see #step
	 */
	public function get maximum():Number
	{
		return this._maximum;
	}

	/**
	 * @private
	 */
	public function set maximum(value:Number):Void
	{
		if(this._maximum == value)
		{
			return;
		}
		this._maximum = value;
		this.invalidate(INVALIDATION_FLAG_DATA);
	}

	/**
	 * @private
	 */
	private var _step:Number = 0;

	/**
	 * As the numeric stepper's buttons are pressed, the value is snapped to
	 * a multiple of the step.
	 *
	 * <p>In the following example, the step is changed to 1:</p>
	 *
	 * <listing version="3.0">
	 * stepper.minimum = 0;
	 * stepper.maximum = 100;
	 * stepper.step = 1;
	 * stepper.value = 12;</listing>
	 *
	 * @default 0
	 *
	 * @see #value
	 * @see #minimum
	 * @see #maximum
	 */
	public function get step():Number
	{
		return this._step;
	}

	/**
	 * @private
	 */
	public function set step(value:Number):Void
	{
		if(this._step == value)
		{
			return;
		}
		this._step = value;
	}

	/**
	 * @private
	 */
	private var currentRepeatAction:Function;

	/**
	 * @private
	 */
	private var _repeatTimer:Timer;

	/**
	 * @private
	 */
	private var _repeatDelay:Number = 0.05;

	/**
	 * The time, in seconds, before actions are repeated. The first repeat
	 * happens after a delay that is five times longer than the following
	 * repeats.
	 *
	 * <p>In the following example, the slider's repeat delay is set to
	 * 500 milliseconds:</p>
	 *
	 * <listing version="3.0">
	 * stepper.repeatDelay = 0.5;</listing>
	 *
	 * @default 0.05
	 */
	public function get repeatDelay():Number
	{
		return this._repeatDelay;
	}

	/**
	 * @private
	 */
	public function set repeatDelay(value:Number):Void
	{
		if(this._repeatDelay == value)
		{
			return;
		}
		this._repeatDelay = value;
		this.invalidate(INVALIDATION_FLAG_STYLES);
	}

	/**
	 * @private
	 */
	private var _buttonLayoutMode:String = BUTTON_LAYOUT_MODE_SPLIT_HORIZONTAL;

	[Inspectable(type="String",enumeration="splitHorizontal,splitVertical,rightSideVertical")]
	/**
	 * How the buttons are positioned relative to the text input.
	 *
	 * <p>In the following example, the button layout is set to place the
	 * buttons on the right side, stacked vertically, for a desktop
	 * appearance:</p>
	 *
	 * <listing version="3.0">
	 * stepper.buttonLayoutMode = NumericStepper.BUTTON_LAYOUT_MODE_RIGHT_SIDE_VERTICAL;</listing>
	 *
	 * @default NumericStepper.BUTTON_LAYOUT_MODE_SPLIT_HORIZONTAL
	 *
	 * @see #BUTTON_LAYOUT_MODE_SPLIT_HORIZONTAL
	 * @see #BUTTON_LAYOUT_MODE_SPLIT_VERTICAL
	 * @see #BUTTON_LAYOUT_MODE_RIGHT_SIDE_VERTICAL
	 */
	public function get buttonLayoutMode():String
	{
		return this._buttonLayoutMode;
	}

	/**
	 * @private
	 */
	public function set buttonLayoutMode(value:String):Void
	{
		if(this._buttonLayoutMode == value)
		{
			return;
		}
		this._buttonLayoutMode = value;
		this.invalidate(INVALIDATION_FLAG_STYLES);
	}

	/**
	 * @private
	 */
	private var _buttonGap:Number = 0;

	/**
	 * The gap, in pixels, between the numeric stepper's increment and
	 * decrement buttons when they are both positioned on the same side. If
	 * the buttons are split between two sides, this value is not used.
	 *
	 * <p>In the following example, the gap between buttons is set to 20 pixels:</p>
	 *
	 * <listing version="3.0">
	 * stepper.buttonLayoutMode = NumericStepper.BUTTON_LAYOUT_MODE_RIGHT_SIDE_VERTICAL;
	 * stepper.buttonGap = 20;</listing>
	 *
	 * @default 0
	 *
	 * @see #textInputGap
	 * @see #buttonLayoutMode
	 */
	public function get buttonGap():Number
	{
		return this._buttonGap;
	}

	/**
	 * @private
	 */
	public function set buttonGap(value:Number):Void
	{
		if(this._buttonGap == value)
		{
			return;
		}
		this._buttonGap = value;
		this.invalidate(INVALIDATION_FLAG_STYLES);
	}

	/**
	 * @private
	 */
	private var _textInputGap:Number = 0;

	/**
	 * The gap, in pixels, between the numeric stepper's text input and its
	 * buttons. If the buttons are split, this gap is used on both sides. If
	 * the buttons both appear on the same side, the gap is used only on
	 * that side.
	 *
	 * <p>In the following example, the gap between the text input and buttons is set to 20 pixels:</p>
	 *
	 * <listing version="3.0">
	 * stepper.textInputGap = 20;</listing>
	 *
	 * @default 0
	 *
	 * @see #buttonGap
	 * @see #buttonLayoutMode
	 */
	public function get textInputGap():Number
	{
		return this._textInputGap;
	}

	/**
	 * @private
	 */
	public function set textInputGap(value:Number):Void
	{
		if(this._textInputGap == value)
		{
			return;
		}
		this._textInputGap = value;
		this.invalidate(INVALIDATION_FLAG_STYLES);
	}

	/**
	 * @private
	 */
	private var _decrementButtonFactory:Function;

	/**
	 * A function used to generate the numeric stepper's decrement button
	 * sub-component. The decrement button must be an instance of
	 * <code>Button</code>. This factory can be used to change properties on
	 * the decrement button when it is first created. For instance, if you
	 * are skinning Feathers components without a theme, you might use this
	 * factory to set skins and other styles on the decrement button.
	 *
	 * <p>The function should have the following signature:</p>
	 * <pre>function():Button</pre>
	 *
	 * <p>In the following example, a custom decrement button factory is passed
	 * to the stepper:</p>
	 *
	 * <listing version="3.0">
	 * slider.decrementButtonFactory = function():Button
	 * {
	 *     var button:Button = new Button();
	 *     button.defaultSkin = new Image( upTexture );
	 *     button.downSkin = new Image( downTexture );
	 *     return button;
	 * };</listing>
	 *
	 * @default null
	 *
	 * @see feathers.controls.Button
	 * @see #decrementButtonProperties
	 */
	public function get decrementButtonFactory():Function
	{
		return this._decrementButtonFactory;
	}

	/**
	 * @private
	 */
	public function set decrementButtonFactory(value:Function):Void
	{
		if(this._decrementButtonFactory == value)
		{
			return;
		}
		this._decrementButtonFactory = value;
		this.invalidate(INVALIDATION_FLAG_DECREMENT_BUTTON_FACTORY);
	}

	/**
	 * @private
	 */
	private var _customDecrementButtonName:String;

	/**
	 * A name to add to the numeric stepper's decrement button
	 * sub-component. Typically used by a theme to provide different skins
	 * to different numeric steppers.
	 *
	 * <p>In the following example, a custom decrement button name is passed
	 * to the stepper:</p>
	 *
	 * <listing version="3.0">
	 * slider.customDecrementButtonName = "my-custom-decrement-button";</listing>
	 *
	 * <p>In your theme, you can target this sub-component name to provide
	 * different skins than the default style:</p>
	 *
	 * <listing version="3.0">
	 * getStyleProviderForClass( Button ).setFunctionForStyleName( "my-custom-decrement-button", setCustomDecrementButtonStyles );</listing>
	 *
	 * @default null
	 *
	 * @see #DEFAULT_CHILD_NAME_DECREMENT_BUTTON
	 * @see feathers.core.FeathersControl#styleNameList
	 * @see #decrementButtonFactory
	 * @see #decrementButtonProperties
	 */
	public function get customDecrementButtonName():String
	{
		return this._customDecrementButtonName;
	}

	/**
	 * @private
	 */
	public function set customDecrementButtonName(value:String):Void
	{
		if(this._customDecrementButtonName == value)
		{
			return;
		}
		this._customDecrementButtonName = value;
		this.invalidate(INVALIDATION_FLAG_DECREMENT_BUTTON_FACTORY);
	}

	/**
	 * @private
	 */
	private var _decrementButtonProperties:PropertyProxy;

	/**
	 * A set of key/value pairs to be passed down to the numeric stepper's
	 * decrement button sub-component. The decrement button is a
	 * <code>feathers.controls.Button</code> instance that is created by
	 * <code>decrementButtonFactory</code>.
	 *
	 * <p>If the subcomponent has its own subcomponents, their properties
	 * can be set too, using attribute <code>&#64;</code> notation. For example,
	 * to set the skin on the thumb which is in a <code>SimpleScrollBar</code>,
	 * which is in a <code>List</code>, you can use the following syntax:</p>
	 * <pre>list.verticalScrollBarProperties.&#64;thumbProperties.defaultSkin = new Image(texture);</pre>
	 *
	 * <p>Setting properties in a <code>decrementButtonFactory</code>
	 * function instead of using <code>decrementButtonProperties</code> will
	 * result in better performance.</p>
	 *
	 * <p>In the following example, the stepper's decrement button properties
	 * are updated:</p>
	 *
	 * <listing version="3.0">
	 * stepper.decrementButtonProperties.defaultSkin = new Image( upTexture );
	 * stepper.decrementButtonProperties.downSkin = new Image( downTexture );</listing>
	 *
	 * @default null
	 *
	 * @see #decrementButtonFactory
	 * @see feathers.controls.Button
	 */
	public function get decrementButtonProperties():Object
	{
		if(!this._decrementButtonProperties)
		{
			this._decrementButtonProperties = new PropertyProxy(childProperties_onChange);
		}
		return this._decrementButtonProperties;
	}

	/**
	 * @private
	 */
	public function set decrementButtonProperties(value:Object):Void
	{
		if(this._decrementButtonProperties == value)
		{
			return;
		}
		if(!value)
		{
			value = new PropertyProxy();
		}
		if(!(value is PropertyProxy))
		{
			var newValue:PropertyProxy = new PropertyProxy();
			for(var propertyName:String in value)
			{
				newValue[propertyName] = value[propertyName];
			}
			value = newValue;
		}
		if(this._decrementButtonProperties)
		{
			this._decrementButtonProperties.removeOnChangeCallback(childProperties_onChange);
		}
		this._decrementButtonProperties = PropertyProxy(value);
		if(this._decrementButtonProperties)
		{
			this._decrementButtonProperties.addOnChangeCallback(childProperties_onChange);
		}
		this.invalidate(INVALIDATION_FLAG_STYLES);
	}

	/**
	 * @private
	 */
	private var _decrementButtonLabel:String = null;

	/**
	 * The text displayed by the decrement button. Often, there is no text
	 * displayed on this button and an icon is used instead.
	 *
	 * <p>In the following example, the decrement button's label is customized:</p>
	 *
	 * <listing version="3.0">
	 * stepper.decrementButtonLabel = "-";</listing>
	 *
	 * @default null
	 */
	public function get decrementButtonLabel():String
	{
		return this._decrementButtonLabel;
	}

	/**
	 * @private
	 */
	public function set decrementButtonLabel(value:String):Void
	{
		if(this._decrementButtonLabel == value)
		{
			return;
		}
		this._decrementButtonLabel = value;
		this.invalidate(INVALIDATION_FLAG_STYLES);
	}

	/**
	 * @private
	 */
	private var _incrementButtonFactory:Function;

	/**
	 * A function used to generate the numeric stepper's increment button
	 * sub-component. The increment button must be an instance of
	 * <code>Button</code>. This factory can be used to change properties on
	 * the increment button when it is first created. For instance, if you
	 * are skinning Feathers components without a theme, you might use this
	 * factory to set skins and other styles on the increment button.
	 *
	 * <p>The function should have the following signature:</p>
	 * <pre>function():Button</pre>
	 *
	 * <p>In the following example, a custom increment button factory is passed
	 * to the stepper:</p>
	 *
	 * <listing version="3.0">
	 * slider.incrementButtonFactory = function():Button
	 * {
	 *     var button:Button = new Button();
	 *     button.defaultSkin = new Image( upTexture );
	 *     button.downSkin = new Image( downTexture );
	 *     return button;
	 * };</listing>
	 *
	 * @default null
	 *
	 * @see feathers.controls.Button
	 * @see #incrementButtonProperties
	 */
	public function get incrementButtonFactory():Function
	{
		return this._incrementButtonFactory;
	}

	/**
	 * @private
	 */
	public function set incrementButtonFactory(value:Function):Void
	{
		if(this._incrementButtonFactory == value)
		{
			return;
		}
		this._incrementButtonFactory = value;
		this.invalidate(INVALIDATION_FLAG_INCREMENT_BUTTON_FACTORY);
	}

	/**
	 * @private
	 */
	private var _customIncrementButtonName:String;

	/**
	 * A name to add to the numeric stepper's increment button
	 * sub-component. Typically used by a theme to provide different skins
	 * to different numeric steppers.
	 *
	 * <p>In the following example, a custom increment button name is passed
	 * to the stepper:</p>
	 *
	 * <listing version="3.0">
	 * slider.customIncrementButtonName = "my-custom-increment-button";</listing>
	 *
	 * <p>In your theme, you can target this sub-component name to provide
	 * different skins than the default style:</p>
	 *
	 * <listing version="3.0">
	 * getStyleProviderForClass( Button ).setFunctionForStyleName( "my-custom-increment-button", setCustomIncrementButtonStyles );</listing>
	 *
	 * @default null
	 *
	 * @see #DEFAULT_CHILD_NAME_INCREMENT_BUTTON
	 * @see feathers.core.FeathersControl#styleNameList
	 * @see #incrementButtonFactory
	 * @see #incrementButtonProperties
	 */
	public function get customIncrementButtonName():String
	{
		return this._customIncrementButtonName;
	}

	/**
	 * @private
	 */
	public function set customIncrementButtonName(value:String):Void
	{
		if(this._customIncrementButtonName == value)
		{
			return;
		}
		this._customIncrementButtonName = value;
		this.invalidate(INVALIDATION_FLAG_INCREMENT_BUTTON_FACTORY);
	}

	/**
	 * @private
	 */
	private var _incrementButtonProperties:PropertyProxy;

	/**
	 * A set of key/value pairs to be passed down to the numeric stepper's
	 * increment button sub-component. The increment button is a
	 * <code>feathers.controls.Button</code> instance that is created by
	 * <code>incrementButtonFactory</code>.
	 *
	 * <p>If the subcomponent has its own subcomponents, their properties
	 * can be set too, using attribute <code>&#64;</code> notation. For example,
	 * to set the skin on the thumb which is in a <code>SimpleScrollBar</code>,
	 * which is in a <code>List</code>, you can use the following syntax:</p>
	 * <pre>list.verticalScrollBarProperties.&#64;thumbProperties.defaultSkin = new Image(texture);</pre>
	 *
	 * <p>Setting properties in a <code>incrementButtonFactory</code>
	 * function instead of using <code>incrementButtonProperties</code> will
	 * result in better performance.</p>
	 *
	 * <p>In the following example, the stepper's increment button properties
	 * are updated:</p>
	 *
	 * <listing version="3.0">
	 * stepper.incrementButtonProperties.defaultSkin = new Image( upTexture );
	 * stepper.incrementButtonProperties.downSkin = new Image( downTexture );</listing>
	 *
	 * @default null
	 *
	 * @see #incrementButtonFactory
	 * @see feathers.controls.Button
	 */
	public function get incrementButtonProperties():Object
	{
		if(!this._incrementButtonProperties)
		{
			this._incrementButtonProperties = new PropertyProxy(childProperties_onChange);
		}
		return this._incrementButtonProperties;
	}

	/**
	 * @private
	 */
	public function set incrementButtonProperties(value:Object):Void
	{
		if(this._incrementButtonProperties == value)
		{
			return;
		}
		if(!value)
		{
			value = new PropertyProxy();
		}
		if(!(value is PropertyProxy))
		{
			var newValue:PropertyProxy = new PropertyProxy();
			for(var propertyName:String in value)
			{
				newValue[propertyName] = value[propertyName];
			}
			value = newValue;
		}
		if(this._incrementButtonProperties)
		{
			this._incrementButtonProperties.removeOnChangeCallback(childProperties_onChange);
		}
		this._incrementButtonProperties = PropertyProxy(value);
		if(this._incrementButtonProperties)
		{
			this._incrementButtonProperties.addOnChangeCallback(childProperties_onChange);
		}
		this.invalidate(INVALIDATION_FLAG_STYLES);
	}

	/**
	 * @private
	 */
	private var _incrementButtonLabel:String = null;

	/**
	 * The text displayed by the increment button. Often, there is no text
	 * displayed on this button and an icon is used instead.
	 *
	 * <p>In the following example, the increment button's label is customized:</p>
	 *
	 * <listing version="3.0">
	 * stepper.incrementButtonLabel = "+";</listing>
	 *
	 * @default null
	 */
	public function get incrementButtonLabel():String
	{
		return this._incrementButtonLabel;
	}

	/**
	 * @private
	 */
	public function set incrementButtonLabel(value:String):Void
	{
		if(this._incrementButtonLabel == value)
		{
			return;
		}
		this._incrementButtonLabel = value;
		this.invalidate(INVALIDATION_FLAG_STYLES);
	}

	/**
	 * @private
	 */
	private var _textInputFactory:Function;

	/**
	 * A function used to generate the numeric stepper's text input
	 * sub-component. The text input must be an instance of <code>TextInput</code>.
	 * This factory can be used to change properties on the text input when
	 * it is first created. For instance, if you are skinning Feathers
	 * components without a theme, you might use this factory to set skins
	 * and other styles on the text input.
	 *
	 * <p>The function should have the following signature:</p>
	 * <pre>function():TextInput</pre>
	 *
	 * <p>In the following example, a custom text input factory is passed
	 * to the stepper:</p>
	 *
	 * <listing version="3.0">
	 * stepper.textInputFactory = function():TextInput
	 * {
	 *     var textInput:TextInput = new TextInput();
	 *     textInput.backgroundSkin = new Image( texture );
	 *     return textInput;
	 * };</listing>
	 *
	 * @default null
	 *
	 * @see feathers.controls.TextInput
	 * @see #textInputProperties
	 */
	public function get textInputFactory():Function
	{
		return this._textInputFactory;
	}

	/**
	 * @private
	 */
	public function set textInputFactory(value:Function):Void
	{
		if(this._textInputFactory == value)
		{
			return;
		}
		this._textInputFactory = value;
		this.invalidate(INVALIDATION_FLAG_TEXT_INPUT_FACTORY);
	}

	/**
	 * @private
	 */
	private var _customTextInputName:String;

	/**
	 * A name to add to the numeric stepper's text input sub-component.
	 * Typically used by a theme to provide different skins to different
	 * text inputs.
	 *
	 * <p>In the following example, a custom text input name is passed
	 * to the stepper:</p>
	 *
	 * <listing version="3.0">
	 * slider.customTextInputName = "my-custom-text-input";</listing>
	 *
	 * <p>In your theme, you can target this sub-component name to provide
	 * different skins than the default style:</p>
	 *
	 * <listing version="3.0">
	 * getStyleProviderForClass( TextInput ).setFunctionForStyleName( "my-custom-text-input", setCustomTextInputStyles );</listing>
	 *
	 * @default null
	 *
	 * @see #DEFAULT_CHILD_NAME_TEXT_INPUT
	 * @see feathers.core.FeathersControl#styleNameList
	 * @see #textInputFactory
	 * @see #textInputProperties
	 */
	public function get customTextInputName():String
	{
		return this._customTextInputName;
	}

	/**
	 * @private
	 */
	public function set customTextInputName(value:String):Void
	{
		if(this._customTextInputName == value)
		{
			return;
		}
		this._customTextInputName = value;
		this.invalidate(INVALIDATION_FLAG_TEXT_INPUT_FACTORY);
	}

	/**
	 * @private
	 */
	private var _textInputProperties:PropertyProxy;

	/**
	 * A set of key/value pairs to be passed down to the numeric stepper's
	 * text input sub-component. The text input is a
	 * <code>feathers.controls.TextInput</code> instance that is created by
	 * <code>textInputFactory</code>.
	 *
	 * <p>If the subcomponent has its own subcomponents, their properties
	 * can be set too, using attribute <code>&#64;</code> notation. For example,
	 * to set the skin on the thumb which is in a <code>SimpleScrollBar</code>,
	 * which is in a <code>List</code>, you can use the following syntax:</p>
	 * <pre>list.verticalScrollBarProperties.&#64;thumbProperties.defaultSkin = new Image(texture);</pre>
	 *
	 * <p>Setting properties in a <code>textInputFactory</code> function
	 * instead of using <code>textInputProperties</code> will result in
	 * better performance.</p>
	 *
	 * <p>In the following example, the stepper's text input properties
	 * are updated:</p>
	 *
	 * <listing version="3.0">
	 * stepper.textInputProperties.backgroundSkin = new Image( texture );</listing>
	 *
	 * @default null
	 *
	 * @see #textInputFactory
	 * @see feathers.controls.TextInput
	 */
	public function get textInputProperties():Object
	{
		if(!this._textInputProperties)
		{
			this._textInputProperties = new PropertyProxy(childProperties_onChange);
		}
		return this._textInputProperties;
	}

	/**
	 * @private
	 */
	public function set textInputProperties(value:Object):Void
	{
		if(this._textInputProperties == value)
		{
			return;
		}
		if(!value)
		{
			value = new PropertyProxy();
		}
		if(!(value is PropertyProxy))
		{
			var newValue:PropertyProxy = new PropertyProxy();
			for(var propertyName:String in value)
			{
				newValue[propertyName] = value[propertyName];
			}
			value = newValue;
		}
		if(this._textInputProperties)
		{
			this._textInputProperties.removeOnChangeCallback(childProperties_onChange);
		}
		this._textInputProperties = PropertyProxy(value);
		if(this._textInputProperties)
		{
			this._textInputProperties.addOnChangeCallback(childProperties_onChange);
		}
		this.invalidate(INVALIDATION_FLAG_STYLES);
	}

	/**
	 * @private
	 */
	override private function draw():Void
	{
		var dataInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_DATA);
		var stylesInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_STYLES);
		var sizeInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_SIZE);
		var stateInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_STATE);
		var decrementButtonFactoryInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_DECREMENT_BUTTON_FACTORY);
		var incrementButtonFactoryInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_INCREMENT_BUTTON_FACTORY);
		var textInputFactoryInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_TEXT_INPUT_FACTORY);
		var focusInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_FOCUS);

		if(decrementButtonFactoryInvalid)
		{
			this.createDecrementButton();
		}

		if(incrementButtonFactoryInvalid)
		{
			this.createIncrementButton();
		}

		if(textInputFactoryInvalid)
		{
			this.createTextInput();
		}

		if(decrementButtonFactoryInvalid || stylesInvalid)
		{
			this.refreshDecrementButtonStyles();
		}

		if(incrementButtonFactoryInvalid || stylesInvalid)
		{
			this.refreshIncrementButtonStyles();
		}

		if(textInputFactoryInvalid || stylesInvalid)
		{
			this.refreshTextInputStyles();
		}

		if(textInputFactoryInvalid || dataInvalid)
		{
			this.refreshTypicalText();
			this.textInput.text = this._value.toString();
		}

		if(decrementButtonFactoryInvalid || stateInvalid)
		{
			this.decrementButton.isEnabled = this._isEnabled;
		}

		if(incrementButtonFactoryInvalid || stateInvalid)
		{
			this.incrementButton.isEnabled = this._isEnabled;
		}

		if(textInputFactoryInvalid || stateInvalid)
		{
			this.textInput.isEnabled = this._isEnabled;
		}

		sizeInvalid = this.autoSizeIfNeeded() || sizeInvalid;

		if(decrementButtonFactoryInvalid || incrementButtonFactoryInvalid || textInputFactoryInvalid ||
			dataInvalid || stylesInvalid || sizeInvalid)
		{
			this.layoutChildren();
		}

		if(sizeInvalid || focusInvalid)
		{
			this.refreshFocusIndicator();
		}
	}

	/**
	 * If the component's dimensions have not been set explicitly, it will
	 * measure its content and determine an ideal size for itself. If the
	 * <code>explicitWidth</code> or <code>explicitHeight</code> member
	 * variables are set, those value will be used without additional
	 * measurement. If one is set, but not the other, the dimension with the
	 * explicit value will not be measured, but the other non-explicit
	 * dimension will still need measurement.
	 *
	 * <p>Calls <code>setSizeInternal()</code> to set up the
	 * <code>actualWidth</code> and <code>actualHeight</code> member
	 * variables used for layout.</p>
	 *
	 * <p>Meant for internal use, and subclasses may override this function
	 * with a custom implementation.</p>
	 */
	private function autoSizeIfNeeded():Boolean
	{
		var needsWidth:Boolean = this.explicitWidth !== this.explicitWidth; //isNaN
		var needsHeight:Boolean = this.explicitHeight !== this.explicitHeight; //isNaN
		if(!needsWidth && !needsHeight)
		{
			return false;
		}

		var newWidth:Number = this.explicitWidth;
		var newHeight:Number = this.explicitHeight;

		this.decrementButton.validate();
		this.incrementButton.validate();
		var oldTextInputWidth:Number = this.textInput.width;
		var oldTextInputHeight:Number = this.textInput.height;
		if(this._buttonLayoutMode == BUTTON_LAYOUT_MODE_RIGHT_SIDE_VERTICAL)
		{
			var maxButtonWidth:Number = Math.max(this.decrementButton.width, this.incrementButton.width);
			this.textInput.minWidth = Math.max(0, this._minWidth - maxButtonWidth);
			this.textInput.maxWidth = Math.max(0, this._maxWidth - maxButtonWidth);
			this.textInput.width = Math.max(0, this.explicitWidth - maxButtonWidth)
			this.textInput.height = this.explicitHeight;
			this.textInput.validate();

			if(needsWidth)
			{
				newWidth = this.textInput.width + maxButtonWidth + this._textInputGap;
			}
			if(needsHeight)
			{
				newHeight = Math.max(this.textInput.height, this.decrementButton.height + this._buttonGap + this.incrementButton.height);
			}
		}
		else if(this._buttonLayoutMode == BUTTON_LAYOUT_MODE_SPLIT_VERTICAL)
		{
			this.textInput.minHeight = Math.max(0, this._minHeight - this.decrementButton.height - this.incrementButton.height);
			this.textInput.maxHeight = Math.max(0, this._maxHeight - this.decrementButton.height - this.incrementButton.height);
			this.textInput.height = Math.max(0, this.explicitHeight - this.decrementButton.height - this.incrementButton.height);
			this.textInput.width = this.explicitWidth;
			this.textInput.validate();

			if(needsWidth)
			{
				newWidth = Math.max(this.decrementButton.width, this.incrementButton.width, this.textInput.width);
			}
			if(needsHeight)
			{
				newHeight = this.decrementButton.height + this.textInput.height + this.incrementButton.height + 2 * this._textInputGap;
			}
		}
		else //split horizontal
		{
			this.textInput.minWidth = Math.max(0, this._minWidth - this.decrementButton.width - this.incrementButton.width);
			this.textInput.maxWidth = Math.max(0, this._maxWidth - this.decrementButton.width - this.incrementButton.width);
			this.textInput.width = Math.max(0, this.explicitWidth - this.decrementButton.width - this.incrementButton.width);
			this.textInput.height = this.explicitHeight;
			this.textInput.validate();

			if(needsWidth)
			{
				newWidth = this.decrementButton.width + this.textInput.width + this.incrementButton.width + 2 * this._textInputGap;
			}
			if(needsHeight)
			{
				newHeight = Math.max(this.decrementButton.height, this.incrementButton.height, this.textInput.height);
			}
		}

		this.textInput.width = oldTextInputWidth;
		this.textInput.height = oldTextInputHeight;
		return this.setSizeInternal(newWidth, newHeight, false);
	}

	/**
	 * @private
	 */
	private function decrement():Void
	{
		this.value = this._value - this._step;
		if(this.textInput.isEditable)
		{
			this.validate();
			this.textInput.selectRange(0, this.textInput.text.length);
		}
	}

	/**
	 * @private
	 */
	private function increment():Void
	{
		this.value = this._value + this._step;
		if(this.textInput.isEditable)
		{
			this.validate();
			this.textInput.selectRange(0, this.textInput.text.length);
		}
	}

	/**
	 * @private
	 */
	private function toMinimum():Void
	{
		this.value = this._minimum;
		if(this.textInput.isEditable)
		{
			this.validate();
			this.textInput.selectRange(0, this.textInput.text.length);
		}
	}

	/**
	 * @private
	 */
	private function toMaximum():Void
	{
		this.value = this._maximum;
		if(this.textInput.isEditable)
		{
			this.validate();
			this.textInput.selectRange(0, this.textInput.text.length);
		}
	}

	/**
	 * Creates and adds the <code>decrementButton</code> sub-component and
	 * removes the old instance, if one exists.
	 *
	 * <p>Meant for internal use, and subclasses may override this function
	 * with a custom implementation.</p>
	 *
	 * @see #decrementButton
	 * @see #decrementButtonFactory
	 * @see #customDecrementButtonName
	 */
	private function createDecrementButton():Void
	{
		if(this.decrementButton)
		{
			this.decrementButton.removeFromParent(true);
			this.decrementButton = null;
		}

		var factory:Function = this._decrementButtonFactory != null ? this._decrementButtonFactory : defaultDecrementButtonFactory;
		var decrementButtonName:String = this._customDecrementButtonName != null ? this._customDecrementButtonName : this.decrementButtonName;
		this.decrementButton = Button(factory());
		this.decrementButton.styleNameList.add(decrementButtonName);
		this.decrementButton.addEventListener(TouchEvent.TOUCH, decrementButton_touchHandler);
		this.addChild(this.decrementButton);
	}

	/**
	 * Creates and adds the <code>incrementButton</code> sub-component and
	 * removes the old instance, if one exists.
	 *
	 * <p>Meant for internal use, and subclasses may override this function
	 * with a custom implementation.</p>
	 *
	 * @see #incrementButton
	 * @see #incrementButtonFactory
	 * @see #customIncrementButtonName
	 */
	private function createIncrementButton():Void
	{
		if(this.incrementButton)
		{
			this.incrementButton.removeFromParent(true);
			this.incrementButton = null;
		}

		var factory:Function = this._incrementButtonFactory != null ? this._incrementButtonFactory : defaultIncrementButtonFactory;
		var incrementButtonName:String = this._customIncrementButtonName != null ? this._customIncrementButtonName : this.incrementButtonName;
		this.incrementButton = Button(factory());
		this.incrementButton.styleNameList.add(incrementButtonName);
		this.incrementButton.addEventListener(TouchEvent.TOUCH, incrementButton_touchHandler);
		this.addChild(this.incrementButton);
	}

	/**
	 * Creates and adds the <code>textInput</code> sub-component and
	 * removes the old instance, if one exists.
	 *
	 * <p>Meant for internal use, and subclasses may override this function
	 * with a custom implementation.</p>
	 *
	 * @see #textInput
	 * @see #textInputFactory
	 * @see #customTextInputName
	 */
	private function createTextInput():Void
	{
		if(this.textInput)
		{
			this.textInput.removeFromParent(true);
			this.textInput = null;
		}

		var factory:Function = this._textInputFactory != null ? this._textInputFactory : defaultTextInputFactory;
		var textInputName:String = this._customTextInputName != null ? this._customTextInputName : this.textInputName;
		this.textInput = TextInput(factory());
		this.textInput.styleNameList.add(textInputName);
		this.textInput.addEventListener(FeathersEventType.ENTER, textInput_enterHandler);
		this.textInput.addEventListener(FeathersEventType.FOCUS_OUT, textInput_focusOutHandler);
		this.textInput.isFocusEnabled = this._focusManager == null;
		this.addChild(this.textInput);
	}

	/**
	 * @private
	 */
	private function refreshDecrementButtonStyles():Void
	{
		for(var propertyName:String in this._decrementButtonProperties)
		{
			var propertyValue:Object = this._decrementButtonProperties[propertyName];
			this.decrementButton[propertyName] = propertyValue;
		}
		this.decrementButton.label = this._decrementButtonLabel;
	}

	/**
	 * @private
	 */
	private function refreshIncrementButtonStyles():Void
	{
		for(var propertyName:String in this._incrementButtonProperties)
		{
			var propertyValue:Object = this._incrementButtonProperties[propertyName];
			this.incrementButton[propertyName] = propertyValue;
		}
		this.incrementButton.label = this._incrementButtonLabel;
	}

	/**
	 * @private
	 */
	private function refreshTextInputStyles():Void
	{
		for(var propertyName:String in this._textInputProperties)
		{
			var propertyValue:Object = this._textInputProperties[propertyName];
			this.textInput[propertyName] = propertyValue;
		}
	}

	/**
	 * @private
	 */
	private function refreshTypicalText():Void
	{
		var typicalText:String = "";
		var maxCharactersBeforeDecimal:Number = Math.max(int(this._minimum).toString().length, int(this._maximum).toString().length, int(this._step).toString().length);

		//roundToPrecision() helps us to avoid numbers like 1.00000000000000001
		//caused by the inaccuracies of floating point math.
		var maxCharactersAfterDecimal:Number = Math.max(roundToPrecision(this._minimum - int(this._minimum), 10).toString().length,
			roundToPrecision(this._maximum - int(this._maximum), 10).toString().length,
			roundToPrecision(this._step - int(this._step), 10).toString().length) - 2;
		if(maxCharactersAfterDecimal < 0)
		{
			maxCharactersAfterDecimal = 0;
		}
		var characterCount:int = maxCharactersBeforeDecimal + maxCharactersAfterDecimal;
		for(var i:int = 0; i < characterCount; i++)
		{
			typicalText += "0";
		}
		if(maxCharactersAfterDecimal > 0)
		{
			typicalText += ".";
		}
		this.textInput.typicalText = typicalText;
	}

	/**
	 * @private
	 */
	private function layoutChildren():Void
	{
		if(this._buttonLayoutMode == BUTTON_LAYOUT_MODE_RIGHT_SIDE_VERTICAL)
		{
			var buttonHeight:Number = (this.actualHeight - this._buttonGap) / 2;
			this.incrementButton.y = 0;
			this.incrementButton.height = buttonHeight;
			this.incrementButton.validate();

			this.decrementButton.y = buttonHeight + this._buttonGap;
			this.decrementButton.height = buttonHeight;
			this.decrementButton.validate();

			var buttonWidth:Number = Math.max(this.decrementButton.width, this.incrementButton.width);
			var buttonX:Number = this.actualWidth - buttonWidth;
			this.decrementButton.x = buttonX;
			this.incrementButton.x = buttonX;

			this.textInput.x = 0;
			this.textInput.y = 0;
			this.textInput.width = buttonX - this._textInputGap;
			this.textInput.height = this.actualHeight;
		}
		else if(this._buttonLayoutMode == BUTTON_LAYOUT_MODE_SPLIT_VERTICAL)
		{
			this.incrementButton.x = 0;
			this.incrementButton.y = 0;
			this.incrementButton.width = this.actualWidth;
			this.incrementButton.validate();

			this.decrementButton.x = 0;
			this.decrementButton.width = this.actualWidth;
			this.decrementButton.validate();
			this.decrementButton.y = this.actualHeight - this.decrementButton.height;

			this.textInput.x = 0;
			this.textInput.y = this.incrementButton.height + this._textInputGap;
			this.textInput.width = this.actualWidth;
			this.textInput.height = Math.max(0, this.actualHeight - this.decrementButton.height - this.incrementButton.height - 2 * this._textInputGap);
		}
		else //split horizontal
		{
			this.decrementButton.x = 0;
			this.decrementButton.y = 0;
			this.decrementButton.height = this.actualHeight;
			this.decrementButton.validate();

			this.incrementButton.y = 0;
			this.incrementButton.height = this.actualHeight;
			this.incrementButton.validate();
			this.incrementButton.x = this.actualWidth - this.incrementButton.width;

			this.textInput.x = this.decrementButton.width + this._textInputGap;
			this.textInput.width = this.actualWidth - this.decrementButton.width - this.incrementButton.width - 2 * this._textInputGap;
			this.textInput.height = this.actualHeight;
		}

		//final validation to avoid juggler next frame issues
		this.textInput.validate();
	}

	/**
	 * @private
	 */
	private function startRepeatTimer(action:Function):Void
	{
		if(this.touchPointID >= 0)
		{
			var exclusiveTouch:ExclusiveTouch = ExclusiveTouch.forStage(this.stage);
			var claim:DisplayObject = exclusiveTouch.getClaim(this.touchPointID)
			if(claim != this)
			{
				if(claim)
				{
					//already claimed by another display object
					return;
				}
				else
				{
					exclusiveTouch.claimTouch(this.touchPointID, this);
				}
			}
		}
		this.currentRepeatAction = action;
		if(this._repeatDelay > 0)
		{
			if(!this._repeatTimer)
			{
				this._repeatTimer = new Timer(this._repeatDelay * 1000);
				this._repeatTimer.addEventListener(TimerEvent.TIMER, repeatTimer_timerHandler);
			}
			else
			{
				this._repeatTimer.reset();
				this._repeatTimer.delay = this._repeatDelay * 1000;
			}
			this._repeatTimer.start();
		}
	}

	/**
	 * @private
	 */
	private function parseTextInputValue():Void
	{
		var newValue:Number = parseFloat(this.textInput.text);
		if(newValue === newValue) //!isNaN
		{
			this.value = newValue;
			if(this.value != newValue && !this.isInvalid(INVALIDATION_FLAG_DATA))
			{
				//if the value setter modified the new value from the text
				//input, and it returned because the modified value is equal
				//to the current value, then we need to force invalidation
				//so that the text input's text is accurate
				this.invalidate(INVALIDATION_FLAG_DATA);
			}
		}
	}

	/**
	 * @private
	 */
	private function childProperties_onChange(proxy:PropertyProxy, name:Object):Void
	{
		this.invalidate(INVALIDATION_FLAG_STYLES);
	}

	/**
	 * @private
	 */
	private function numericStepper_removedFromStageHandler(event:Event):Void
	{
		this.touchPointID = -1;
	}

	/**
	 * @private
	 */
	override private function focusInHandler(event:Event):Void
	{
		super.focusInHandler(event);
		if(this.textInput.isEditable)
		{
			this.textInput.setFocus();
			this.textInput.selectRange(0, this.textInput.text.length);
		}
		this.stage.addEventListener(KeyboardEvent.KEY_DOWN, stage_keyDownHandler);
	}

	/**
	 * @private
	 */
	override private function focusOutHandler(event:Event):Void
	{
		super.focusOutHandler(event);
		this.textInput.clearFocus();
		this.stage.removeEventListener(KeyboardEvent.KEY_DOWN, stage_keyDownHandler);
	}

	/**
	 * @private
	 */
	private function textInput_enterHandler(event:Event):Void
	{
		this.parseTextInputValue();
	}

	/**
	 * @private
	 */
	private function textInput_focusOutHandler(event:Event):Void
	{
		this.parseTextInputValue();
	}

	/**
	 * @private
	 */
	private function decrementButton_touchHandler(event:TouchEvent):Void
	{
		if(!this._isEnabled)
		{
			this.touchPointID = -1;
			return;
		}

		if(this.touchPointID >= 0)
		{
			var touch:Touch = event.getTouch(this.decrementButton, TouchPhase.ENDED, this.touchPointID);
			if(!touch)
			{
				return;
			}
			this.touchPointID = -1;
			this._repeatTimer.stop();
			this.dispatchEventWith(FeathersEventType.END_INTERACTION);
		}
		else //if we get here, we don't have a saved touch ID yet
		{
			touch = event.getTouch(this.decrementButton, TouchPhase.BEGAN);
			if(!touch)
			{
				return;
			}
			this.touchPointID = touch.id;
			this.dispatchEventWith(FeathersEventType.BEGIN_INTERACTION);
			this.decrement();
			this.startRepeatTimer(this.decrement);
		}
	}

	/**
	 * @private
	 */
	private function incrementButton_touchHandler(event:TouchEvent):Void
	{
		if(!this._isEnabled)
		{
			this.touchPointID = -1;
			return;
		}

		if(this.touchPointID >= 0)
		{
			var touch:Touch = event.getTouch(this.incrementButton, TouchPhase.ENDED, this.touchPointID);
			if(!touch)
			{
				return;
			}
			this.touchPointID = -1;
			this._repeatTimer.stop();
			this.dispatchEventWith(FeathersEventType.END_INTERACTION);
		}
		else //if we get here, we don't have a saved touch ID yet
		{
			touch = event.getTouch(this.incrementButton, TouchPhase.BEGAN);
			if(!touch)
			{
				return;
			}
			this.touchPointID = touch.id;
			this.dispatchEventWith(FeathersEventType.BEGIN_INTERACTION);
			this.increment();
			this.startRepeatTimer(this.increment);
		}
	}

	/**
	 * @private
	 */
	private function stage_keyDownHandler(event:KeyboardEvent):Void
	{
		if(event.keyCode == Keyboard.HOME)
		{
			this.toMinimum();
		}
		else if(event.keyCode == Keyboard.END)
		{
			this.toMaximum();
		}
		else if(event.keyCode == Keyboard.UP)
		{
			this.increment();
		}
		else if(event.keyCode == Keyboard.DOWN)
		{
			this.decrement();
		}
	}

	/**
	 * @private
	 */
	private function repeatTimer_timerHandler(event:TimerEvent):Void
	{
		if(this._repeatTimer.currentCount < 5)
		{
			return;
		}
		this.currentRepeatAction();
	}
}
