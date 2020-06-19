package uk.aidanlee.flurry.api.input;

enum KeyModifier
{
    None;
    LeftShift;
    RightShift;
    LeftControl;
    RightControl;
    LeftAlt;
    RightAlt;
    LeftMeta;
    RightMeta;
    NumLock;
    CapsLock;
    Mode;
    Control;
    Shift;
    Alt;
    Meta;
}

enum TextEventType
{
    Unknown;
    Edit;
    Input;
}

enum GamepadDeviceEventType
{
    Unknown;
    DeviceAdded;
    DeviceRemoved;
    DeviceRemapped;
}
