std = "lua54"
max_line_length = false

globals = {
    "EmpowerSquareDB",
    "EmpowerSquareLogic",
    "SLASH_EMPOWERSQUARE1",
    "SLASH_EMPOWERSQUARE2",
    SlashCmdList = {
        fields = {
            EMPOWERSQUARE = {},
        },
    },
}

read_globals = {
    "CreateFrame",
    "UIParent",
    "C_Timer",
    "GetTime",
    "UnitCastingInfo",
    "UnitChannelInfo",
    "UnitEmpoweredStageDurations",
    "SlashCmdList",
    "UIDropDownMenu_AddButton",
    "UIDropDownMenu_CreateInfo",
    "UIDropDownMenu_Initialize",
    "UIDropDownMenu_JustifyText",
    "UIDropDownMenu_SetSelectedValue",
    "UIDropDownMenu_SetText",
    "UIDropDownMenu_SetWidth",
    "unpack",
}

-- WoW frame callbacks receive self; keep signature, silence unused.
unused_args = false
