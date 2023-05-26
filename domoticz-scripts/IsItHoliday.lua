--++++--------------------- Mandatory: Set your values and device names below this Line --------------------------------------
local userDefined_httpResponse      = "getHolidays_Response"    -- This will trigger the script after the return
local userDefined_stringVariable    = "Holiday"                 -- Name of your uservariable created as type string (mandatory)
local userDefined_noPublicHoliday   = "Workday" --"is geen feestdag"        -- Localized text for no public holiday
local userDefined_country           = "DEU"                      -- Also used for language
local userDefined_region            = "BW"                        -- mandatory if regions are defined for your country
-- find list of valid regions at https://kayaposoft.com/enrico/json/v2.0?action=getSupportedCountries

----------------------------------------- Optional: presenting the result ----------------------------------------------------
--local userDefined_integerVariable   = "HolidayInteger"    -- Name of your uservariable if you created it as type integer or set to line to comment
--local userDefined_textDevice        = "HolidayText"       -- Name with quotes or idx without when created as virtual text device or set to line to comment
--local userDefined_alertDevice       = "HolidayAlert"      -- Name with quotes or idx without when created as virtual alert device or set to line to comment
local userDefined_switchDevice      = 11                 -- Name with quotes or idx without when created as virtual switch or set to line to comment
local userDefined_noDataMessage     = "Problem with data in Enricp response (data seems to be missing)"
local userDefined_httpNotOKMessage  = "Problem with response from Enrico (not ok)"
--++++---------------------------- Set your values and device names above this Line --------------------------------------------

return {
    on      =   {   timer           =   { "at 00:01","at 06:02" },               -- daily run (One extra for redundancy)
                    variables       =   { userDefined_stringVariable },
                    httpResponses   =   { userDefined_httpResponse }               -- Trigger the handle Json part
                },
    logging =   {   level           =   domoticz.LOG_ERROR,
                    marker          =   "getHolidays"
                },
    data    =   {   holidays              = {initial = {} },                     -- Store holidaysTable in dzVents persistent data
                    refreshDate           = {initial = "" },
                    country               = {initial = userDefined_country },
                    region                = {initial = userDefined_region },
                },

    execute = function(dz, triggerObject)
        
        -- Compose URL and send 
        local function getHolidays(secondsFromNow)
            secondsFromNow = secondsFromNow or 1                   -- catch empty parm
            local yearsAhead         = 1 * 366 * 24 * 3600
            local getHolidays_url  = "https://kayaposoft.com/enrico/json/v2.0/" ..
                                     "?action=getHolidaysForDateRange"..
                                    "&fromDate=" .. os.date("%d-%m-%Y")  ..                              -- today
                                    "&toDate=".. os.date("%d-%m-%Y",os.time() + yearsAhead ) ..      -- today + yearsAhead years
                                    "&country=" .. userDefined_country ..
                                    "&region=" .. userDefined_region ..
                                    "&holidayType=public_holiday"
            dz.openURL  ({
                            url = getHolidays_url ,
                            method = "GET",
                            callback = userDefined_httpResponse,
                        }).afterSec(secondsFromNow)
        end

        -- walk trough the table to find today's date    
        local function processHolidays()
            local holidayTable  = dz.data.holidays
            local today         = os.date("*t")

            for i = 1,#holidayTable do
                if holidayTable[i].date.day == today.day and holidayTable[i].date.month == today.month and holidayTable[i].date.year == today.year then
                   return holidayTable[i].name[1].text                            -- holiday found
                end
            end
            return userDefined_noPublicHoliday
        end

        -- update variables and devices
        local function setDomoticzDevices(holidayName)
            local fullText  = os.date(" %A %d %B, %Y"):gsub(" 0"," ") .. ": " ..  holidayName
            --dz.variables(userDefined_stringVariable).set(fullText).silent()
            dz.variables(userDefined_stringVariable).set(holidayName).silent()
            if userDefined_integerVariable then
                dz.variables(userDefined_integerVariable).set(0)
                if holidayName ~= userDefined_noPublicHoliday then
                    dz.variables(userDefined_integerVariable).set(1)
                end
            end

            if userDefined_textDevice then
                dz.devices(userDefined_textDevice).updateText(fullText)
            end

            if userDefined_alertDevice then
                alertTable = {dz.ALERTLEVEL_YELLOW,        -- Sunday
                              dz.ALERTLEVEL_GREEN,         -- Monday
                              dz.ALERTLEVEL_GREEN,         -- Tuesday
                              dz.ALERTLEVEL_GREEN,         -- Wednesday
                              dz.ALERTLEVEL_GREEN,         -- Thursday
                              dz.ALERTLEVEL_GREEN,         -- Fridayday
                              dz.ALERTLEVEL_ORANGE,         -- Saturday
                              dz.ALERTLEVEL_RED            -- Holiday
                                 }
                if holidayName == userDefined_noPublicHoliday then
                    dz.devices(userDefined_alertDevice).updateAlertSensor(alertTable[os.date("*t").wday], fullText)
                else
                    dz.devices(userDefined_alertDevice).updateAlertSensor(alertTable[#alertTable], fullText)
                end
            end

            if userDefined_switchDevice then
                if holidayName ~= userDefined_noPublicHoliday then
                    dz.devices(userDefined_switchDevice).switchOn() --.checkFirst()
                else
                    dz.devices(userDefined_switchDevice).switchOff() --.checkFirst()
                end
            end
        end

        -- set number of days since last refresh 
        local function daysSinceLastRefresh()
            local lastRefreshDate
            if dz.data.refreshDate ~= "" then
                lastRefreshDate = dz.data.refreshDate   -- dz.data.refreshDate was set in earlier run
            else
                lastRefreshDate = os.date("*t",1)        -- use very old date because dz.data.refreshDate is not yet set
            end
            return os.difftime(os.time(), os.time(lastRefreshDate)) / (3600*24)
        end
        
        -- Add entry to log and notify to all subsystems
        local function errorMessage(message)
            dz.log(message,dz.LOG_ERROR)
            dz.notify(message)
        end       
        
        -- Store table and date in persisstent data 
        local function updatePersistentData()
            if #triggerObject.json > 0 then
                dz.data.holidays    = triggerObject.json           -- fill dz.data with the complete httpResponse
                dz.data.refreshDate = os.date('*t')         -- set refreshDate to current datetime
                return true
            else
                return false
            end
        end
        
        -- Do we need to get fresh data ? 
        local function freshData()
            local daysBetweenRefresh = 60
           
            return   dz.data.holidays[1] ~= nil  and
                     daysSinceLastRefresh() < daysBetweenRefresh and
                     userDefined_country == dz.data.country and
                     userDefined_region  == dz.data.region
        end
        
        -- Main 
        if triggerObject.isHTTPResponse then
            if triggerObject.ok then
                if updatePersistentData() then
                    setDomoticzDevices(processHolidays())
                else
                    errorMessage(userDefined_noDataMessage)   -- Forgot to enter valid country / region ?
                end
            else
                errorMessage(userDefined_httpNotOKMessage)
                getHolidays(600)                            -- response not OK, try again after 10 minutes
            end
        else
            if freshData() then
                setDomoticzDevices(processHolidays())
            else                                            -- dz.data does not contain any data or data needs to be refreshed
                getHolidays()
            end
        end
    end
}