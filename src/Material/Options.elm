module Material.Options
    exposing
        ( Property
        , cs
        , css
        , many
        , nop
        , data
        , aria
        , when
        , styled
        , attribute
        , input
        , container
        , onClick
        , onDoubleClick
        , onMouseDown
        , onMouseUp
        , onMouseEnter
        , onMouseLeave
        , onMouseOver
        , onMouseOut
        , onCheck
        , onToggle
        , onBlur
        , onFocus
        , onInput
        , on
        , onWithOptions
        )

{-| Properties, styles, and event definitions.

@docs Property, styled
@docs data, aria, id
@docs cs, css
@docs attribute, container, input, many, nop, stylesheet, when
@docs on
@docs onBlur
@docs onCheck
@docs onClick
@docs onDoubleClick
@docs onFocus
@docs onInput
@docs onMouseDown
@docs onMouseEnter
@docs onMouseLeave
@docs onMouseOut
@docs onMouseOver
@docs onMouseUp
@docs onToggle
@docs onWithOptions
@docs dispatch
-}

import Html exposing (Html, Attribute)
import Html.Attributes
import Html.Events
import Json.Decode as Json
import Material.Internal.Options as Internal exposing (..)



-- PROPERTIES


{-|
Type of elm-mdl optional properties. (Do not confuse these with Html properties
or `Html.Attributes.property`.)

The type variable `c` identifies the component the property is for. You never
have to set it yourself. The type variable `m` is the type of your messages
carried by the optional property, if applicable. You should set this yourself.

The elements of the penultimate argument in the above call to
`Textfield.render` has this type, specifically:

    List (Property (Textfield.Config) Msg)
-}
type alias Property c m =
    Internal.Property c m


{-| Universally applicable elm-mdl properties, e.g., `Options.css`,
`Typography.*`, or `Options.onClick`, may be applied to ordinary `Html` values
such as `Html.h4` using `styled` below.
-}
type alias Style m = -- TODO: remove
    Property () m


{-| Apply properties to a standard Html element.
-}
styled : (List (Attribute m) -> a) -> List (Property c m) -> a
styled ctor props =
    ctor
        (addAttributes
            (collect_ props)
            []
        )


{-| Add an HTML class to a component. (Name chosen to avoid clashing with
Html.Attributes.class.)
-}
cs : String -> Property c m
cs c =
    Class c


{-| Add a CSS style to a component.
-}
css : String -> String -> Property c m
css key value =
    CSS ( key, value )


{-| Multiple options.
-}
many : List (Property c m) -> Property c m
many =
    Many


{-| Do nothing. Convenient when the absence or
presence of Options depends dynamically on other values, e.g.,

    Options.div
      [ if model.isActive then cs "active" else nop ]
      [ ... ]
-}
nop : Property c m
nop =
    None


{-| HTML data-* attributes. Prefix "data-" is added automatically.
-}
data : String -> String -> Property c m
data key val =
    Attribute (Html.Attributes.attribute ("data-" ++ key) val)


{-| TODO
-}
aria : String -> String -> Property c m
aria key val =
    Attribute (Html.Attributes.attribute ("aria-" ++ key) val)


{-| Conditional option. When the guard evaluates to `true`, the option is
applied; otherwise it is ignored. Use like this:

    Button.disabled |> when (not model.isRunning)
-}
when : Bool -> Property c m -> Property c m
when guard prop  =
    if guard then
        prop
    else
        nop


{-| Install arbitrary `Html.Attribute`.

```elm
import Html
import Html.Attributes as Html
import Material.Options as Options exposing (styled)

styled Html.div
    [ Options.attribute <| Html.title "title"
    ]
    [ …
    ]
```
-}
attribute : Html.Attribute Never -> Property c m
attribute =
    Attribute << Html.Attributes.map never


{-| Apply argument options to `input` element in component implementation.
-}
input : List (Style m) -> Property (Input c m) m
input =
    Internal.input


{-| Apply argument options to container element in component implementation.
-}
container : List (Style m) -> Property (Container c m) m
container =
    Internal.container



-- EVENTS


{-| Add custom event handlers
-}
on : String -> Json.Decoder m -> Property c m
on event =
    Listener event Nothing


{-| -}
onClick : msg -> Property c msg
onClick msg =
    on "click" (Json.succeed msg)


{-| -}
onDoubleClick : msg -> Property c msg
onDoubleClick msg =
    on "dblclick" (Json.succeed msg)


{-| -}
onMouseDown : msg -> Property c msg
onMouseDown msg =
    on "mousedown" (Json.succeed msg)


{-| -}
onMouseUp : msg -> Property c msg
onMouseUp msg =
    on "mouseup" (Json.succeed msg)


{-| -}
onMouseEnter : msg -> Property c msg
onMouseEnter msg =
    on "mouseenter" (Json.succeed msg)


{-| -}
onMouseLeave : msg -> Property c msg
onMouseLeave msg =
    on "mouseleave" (Json.succeed msg)


{-| -}
onMouseOver : msg -> Property c msg
onMouseOver msg =
    on "mouseover" (Json.succeed msg)


{-| -}
onMouseOut : msg -> Property c msg
onMouseOut msg =
    on "mouseout" (Json.succeed msg)


{-| Capture [change](https://developer.mozilla.org/en-US/docs/Web/Events/change)
events on checkboxes. It will grab the boolean value from `event.target.checked`
on any input event.
Check out [targetChecked](#targetChecked) for more details on how this works.
-}
onCheck : (Bool -> msg) -> Property c msg
onCheck =
    (flip Json.map Html.Events.targetChecked) >> on "change"


{-| -}
onToggle : msg -> Property c msg
onToggle msg =
    on "change" (Json.succeed msg)



-- FOCUS EVENTS


{-| -}
onBlur : msg -> Property c msg
onBlur msg =
    on "blur" (Json.succeed msg)


{-| -}
onFocus : msg -> Property c msg
onFocus msg =
    on "focus" (Json.succeed msg)


{-| -}
onInput : (String -> m) -> Property c m
onInput f =
    on "input" (Json.map f Html.Events.targetValue)


{-| Add custom event handlers with options
-}
onWithOptions : String -> Html.Events.Options -> Json.Decoder m -> Property c m
onWithOptions evt options =
    Listener evt (Just options)



-- DISPATCH


{-| No-shorthand multiple-event dispatch.

NB! You are _extremely_ unlikely to need this.

You need this optional property in exactly these circumstances:
1. You are using an elm-mdl component which has a `render` function.
2. You are not using this `render` function, instead calling `view`.
3. You installed an `on*` handler on the component, but that handler does not
seem to take effect.

What's happening in this case is that elm-mdl has an internal handler for the
same event as your custom handler; e.g., you install `onBlur` on
`Textfield`, but `Textfield`'s has an internal `onBlur` handler.

In this case you need to tell the component how to dispatch multiple messages
(one for you, one for itself) in response to a single DOM event. You do so by
providing a means of folding a list of messages into a single message. (See
the [Dispatch](https://github.com/vipentti/elm-dispatch) library for one way to define such a function.)

The `render` function does all this automatically. If you are calling `render`,
you do not need this property.

Example use:


    type Msg =
      ...
      | Textfield (Textfield.Msg)
      | MyBlurMsg
      | Batch (List Msg)

    ...

      Textfield.view Textfield model.textfield
        [ Options.dispatch Batch
        , Options.onBlur MyBlurMsg
        ]
        [ ]
-}
dispatch : (List m -> m) -> Property c m
dispatch =
    Lift << Json.map
