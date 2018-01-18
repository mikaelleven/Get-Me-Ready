
function reloadConfig(files)
    doReload = false
    for _,file in pairs(files) do
        if file:sub(-4) == ".lua" then
            doReload = true
        end
    end
    if doReload then
        hs.reload()
    end
end
myWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()
hs.alert.show("Config loaded")


-- -- Clean pasteboard
-- local function cleanPasteboard()
--     local pb = hs.pasteboard.contentTypes()
--     local contains = hs.fnutils.contains
--     if contains(pb, "com.apple.webarchive") and contains(pb, "public.rtf") then
--         hs.pasteboard.setContents(hs.pasteboard.getContents())
--     end
-- end
  
-- local messagesWindowFilter = hs.window.filter.new(false):setAppFilter('Messages')
-- messagesWindowFilter:subscribe(hs.window.filter.windowFocused, cleanPasteboard)


