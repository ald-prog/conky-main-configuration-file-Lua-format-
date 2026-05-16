-- -------------------------------------------------------------------
-- File: conky.lua
-- Type: Lua helper functions for Conky
-- By Arnold
-- Last modified: 2026-05-15
-- Version: 2
-- -------------------------------------------------------------------
-- Changes from v1:
--   * Fixed indentation (was broken from cascading editor paste)
--   * Added cache layer: static values fetched once, slow io.popen
--     calls throttled -- stops ALL blinking
--       cpu_model / gpu_model / gpu_vendor / resolution  -> once only
--       cpu_temp / gpu_temp / nvme_temp                  -> every 5 cycles (~10s)
--       disk_temp (HDD)                                  -> every 10 cycles (~20s)
--   * Added conky_get_gpu_freq()       reads sysfs directly, no shell
--   * Added conky_get_gpu_temp()       throttled, sysfs + sensors
--   * Added conky_get_gpu_temp_color() throttled
--   * Added conky_get_nvme_temp_color() was missing in v1
--   * Added conky_get_disk_temp(dev)   replaces ${hddtemp} built-in
--       chain: sysfs hwmon -> smartctl (attr 194) -> hddtemp binary
-- -------------------------------------------------------------------

-- ── Cache helpers ─────────────────────────────────────────────────

local _cache = {}
local _count = {}

local function cache_once(key, fn)
if _cache[key] == nil then
    local v = fn()
    _cache[key] = (v and v ~= "") and v or "N/A"
    end
    return _cache[key]
    end

    local function cache_timed(key, interval, fn)
    if _cache[key] == nil or (_count[key] or 0) >= interval then
        local v = fn()
        _cache[key] = (v and v ~= "") and v or "N/A"
        _count[key] = 0
        else
            _count[key] = (_count[key] or 0) + 1
            end
            return _cache[key]
            end

            local function shell(cmd)
            local h = io.popen(cmd .. " 2>/dev/null")
            if not h then return nil end
                local r = h:read("*a")
                h:close()
                r = r:gsub("^%s*(.-)%s*$", "%1")
                return r ~= "" and r or nil
                end

                -- ── Distro ────────────────────────────────────────────────────────

                function conky_get_distro()
                return cache_once("distro", function()
                return shell("grep '^PRETTY_NAME=' /etc/os-release | cut -d= -f2 | tr -d '\"'")
                or shell("grep '^NAME=' /etc/os-release | cut -d= -f2 | tr -d '\"'")
                or shell("uname -o")
                end)
                end

                -- ── CPU ───────────────────────────────────────────────────────────

                function conky_get_cpu_model()
                return cache_once("cpu_model", function()
                return shell(
                    "grep 'model name' /proc/cpuinfo | head -1"
                    .. " | sed -e 's/model name.*: //'"
                    .. "       -e 's/(R)//g'"
                    .. "       -e 's/(TM)//g'"
                    .. "       -e 's/ CPU//g'"
                    .. "       -e 's/  */ /g'"
                    .. "       -e 's/ @ .*//'")
                end)
                end

                -- sensors can take 200-800ms; throttle to every 5 cycles (~10s)
                function get_cpu_temp_value()
                return cache_timed("cpu_temp_value", 5, function()
                local raw = shell([[
                    sensors | awk '/Package id 0:/ {
                        gsub(/[+°C]/, "", $4)
                        split($4, a, ".")
                        print a[1]
                    }'
                ]])

                return tonumber(raw)
                end)
                end

                function conky_get_cpu_temp()
                local temp = get_cpu_temp_value()

                return temp and (temp .. "°C") or "N/A"
                end

                function conky_get_cpu_temp_color()
                local temp = get_cpu_temp_value()

                if not temp then
                    return "${color8}"
                    elseif temp >= 80 then
                        return "${color4}"
                        elseif temp >= 65 then
                            return "${color5}"
                            else
                                return "${color8}"
                                end
                                end

                -- ── Network ───────────────────────────────────────────────────────

                function conky_get_net_rx(iface)
                local f = io.open("/sys/class/net/" .. iface .. "/statistics/rx_bytes", "r")
                if not f then return "0.00 MB" end
                    local b = f:read("*n"); f:close()
                    return b and string.format("%.2f MB", b / 1048576) or "0.00 MB"
                    end

                    function conky_get_net_tx(iface)
                    local f = io.open("/sys/class/net/" .. iface .. "/statistics/tx_bytes", "r")
                    if not f then return "0.00 MB" end
                        local b = f:read("*n"); f:close()
                        return b and string.format("%.2f MB", b / 1048576) or "0.00 MB"
                        end

                        function conky_get_wifi_rx()
                        local total = 0
                        for _, iface in ipairs({"wlan0", "wlan1"}) do
                            local f = io.open("/sys/class/net/" .. iface .. "/statistics/rx_bytes", "r")
                            if f then
                                local b = f:read("*n")
                                if b then total = total + b end
                                    f:close()
                                    end
                                    end
                                    return string.format("%.2f MB", total / 1048576)
                                    end

                                    function conky_get_wifi_tx()
                                    local total = 0
                                    for _, iface in ipairs({"wlan0", "wlan1"}) do
                                        local f = io.open("/sys/class/net/" .. iface .. "/statistics/tx_bytes", "r")
                                        if f then
                                            local b = f:read("*n")
                                            if b then total = total + b end
                                                f:close()
                                                end
                                                end
                                                return string.format("%.2f MB", total / 1048576)
                                                end

                                                -- ── GPU ───────────────────────────────────────────────────────────

                                                function conky_get_gpu_model()
                                                return cache_once("gpu_model", function()
                                                return shell("lspci | grep -i 'vga' | cut -d: -f3 | sed 's/^ *//'")
                                                end)
                                                end

                                                function conky_get_gpu_vendor()
                                                local handle = io.popen("lspci -nn 2>/dev/null | grep -i 'vga' | cut -d '[' -f2 | cut -d ']' -f1")
                                                if not handle then
                                                    return "N/A"
                                                    end
                                                    local result = handle:read("*a")
                                                    handle:close()
                                                    return result:gsub("^%s*(.-)%s*$", "%1")
                                                    end

                                                -- xdpyinfo is fast but still spawned every 2s in v1 -- cache it once
                                                function conky_get_resolution()
                                                return cache_once("resolution", function()
                                                return shell("xdpyinfo | grep dimensions | awk '{print $2}'")
                                                or shell("xrandr | grep ' connected' | grep -oP '\\d+x\\d+' | head -1")
                                                end)
                                                end

                                                -- Pure sysfs read -- no shell fork, safe to call every cycle
                                                function conky_get_gpu_freq()
                                                local f = io.open("/sys/class/drm/card0/gt_cur_freq_mhz", "r")
                                                if not f then return "N/A" end
                                                    local v = f:read("*n"); f:close()
                                                    return v and tostring(v) or "N/A"
                                                    end

                                                    function conky_get_gpu_usage()
                                                    -- intel_gpu_top (needs sudoers NOPASSWD for this specific command)
                                                    local raw = shell(
                                                        "sudo timeout 0.1 intel_gpu_top -J -s 100"
                                                        .. " | grep -oP '\"busy\":\\s*\\K[0-9.]+' | head -1")
                                                    if raw and tonumber(raw) then return string.format("%.0f", tonumber(raw)) end

                                                        -- Frequency ratio as usage proxy (pure sysfs)
                                                        local fc = io.open("/sys/class/drm/card0/gt_cur_freq_mhz", "r")
                                                        local fm = io.open("/sys/class/drm/card0/gt_max_freq_mhz", "r")
                                                        if fc and fm then
                                                            local cur, max = fc:read("*n"), fm:read("*n")
                                                            fc:close(); fm:close()
                                                            if cur and max and max > 0 then
                                                                return string.format("%.0f", (cur / max) * 100)
                                                                end
                                                                else
                                                                    if fc then fc:close() end
                                                                        if fm then fm:close() end
                                                                            end

                                                                            raw = shell("timeout 0.1 radeontop -d - -l 1 | grep -oP 'gpu\\s+\\K[0-9.]+'")
                                                                            if raw and tonumber(raw) then return raw end

                                                                                return "N/A"
                                                                                end

                                                                                function conky_get_gpu_temp()
                                                                                return cache_timed("gpu_temp", 5, function()
                                                                                -- Intel iGPU sysfs
                                                                                local f = io.open("/sys/class/drm/card0/device/hwmon/hwmon0/temp1_input", "r")
                                                                                if f then
                                                                                    local v = f:read("*n"); f:close()
                                                                                    if v then return string.format("%.0f°C", v / 1000) end
                                                                                        end
                                                                                        -- sensors fallback (AMD / Nvidia / Intel fallback)
                                                                                local raw = shell(
                                                                                    "sensors | grep -iE 'gpu|edge|junction'"
                                                                                    .. " | awk '{print $2}' | tr -d '+°C' | head -1")
                                                                                if raw and tonumber(raw) then return string.format("%.0f°C", tonumber(raw)) end
                                                                                    return "N/A"
                                                                                    end)
                                                                                end

                                                                                function conky_get_gpu_temp_color()
                                                                                return cache_timed("gpu_temp_color", 5, function()
                                                                                local temp
                                                                                local f = io.open("/sys/class/drm/card0/device/hwmon/hwmon0/temp1_input", "r")
                                                                                if f then
                                                                                    local v = f:read("*n"); f:close()
                                                                                    if v then temp = v / 1000 end
                                                                                        end
                                                                                        if not temp then
                                                                                            local raw = shell(
                                                                                                "sensors | grep -iE 'gpu|edge'"
                                                                                                .. " | awk '{print $2}' | tr -d '+°C' | head -1")
                                                                                            temp = tonumber(raw)
                                                                                            end
                                                                                            if not temp then return "${color8}" end
                                                                                                if     temp >= 80 then return "${color4}"
                                                                                                    elseif temp >= 65 then return "${color5}"
                                                                                                        else                    return "${color8}" end
                                                                                                            end)
                                                                                end

                                                                                -- ── NVMe ──────────────────────────────────────────────────────────

                                                                                function conky_get_nvme_temp()
                                                                                return cache_timed("nvme_temp", 5, function()
                                                                                local raw = shell("cat /sys/class/nvme/nvme0/device/hwmon/*/temp1_input | head -1")
                                                                                if raw then
                                                                                    local v = tonumber(raw)
                                                                                    if v then return string.format("%.0f", v / 1000) end
                                                                                        end

                                                                                        raw = shell([[
                                                                                            for f in /sys/class/hwmon/hwmon*/name; do
                                                                                                grep -q nvme "$f" && cat "$(dirname $f)/temp1_input" && break
                                                                                                done]])
                                                                                        if raw then
                                                                                            local v = tonumber(raw)
                                                                                            if v then return string.format("%.0f", v / 1000) end
                                                                                                end

                                                                                                raw = shell("sensors | grep -iE 'nvme|Composite' | grep -oP '\\+\\K[0-9.]+' | head -1")
                                                                                                if raw and tonumber(raw) then return string.format("%.0f", tonumber(raw)) end

                                                                                                    raw = shell("sudo smartctl -A /dev/nvme0n1 | grep -i temperature | awk '{print $2}' | head -1")
                                                                                                    if raw and tonumber(raw) then return raw end

                                                                                                        return "N/A"
                                                                                                        end)
                                                                                end

                                                                                function conky_get_nvme_temp_color()
                                                                                return cache_timed("nvme_temp_color", 5, function()
                                                                                local temp
                                                                                local raw = shell("cat /sys/class/nvme/nvme0/device/hwmon/*/temp1_input | head -1")
                                                                                if raw then
                                                                                    local v = tonumber(raw)
                                                                                    if v then temp = v / 1000 end
                                                                                        end
                                                                                        if not temp then
                                                                                            local s = shell("sensors | grep -iE 'nvme|Composite' | grep -oP '\\+\\K[0-9.]+' | head -1")
                                                                                            temp = tonumber(s)
                                                                                            end
                                                                                            if not temp then return "${color6}" end
                                                                                                if     temp >= 70 then return "${color4}"
                                                                                                    elseif temp >= 55 then return "${color5}"
                                                                                                        else                    return "${color6}" end
                                                                                                            end)
                                                                                end

                                                                                -- ── HDD / SATA Disk Temperature ───────────────────────────────────


                                                                                function conky_get_disk_temp(dev)

                                                                                if not dev:match("^[%w%d]+$") then
                                                                                    return "N/A"
                                                                                    end

                                                                                    local key = "hdd_temp_" .. dev

                                                                                    return cache_timed(key, 10, function()

                                                                                    local raw

                                                                                    -- SMART method
                                                                                    raw = shell([[
                                                                                        sudo -n smartctl -A /dev/]] .. dev .. [[ 2>/dev/null |
                                                                                        awk '
                                                                                    /Temperature_Celsius|Airflow_Temperature_Cel|Temperature:/ {
                                                                                        for(i=1;i<=NF;i++)
                                                                                            if($i ~ /^[0-9]+$/)
                                                                                                temp=$i
                                                                                    }
                                                                                    END {print temp}'
                                                                                        ]])

                                                                                    local temp = tonumber(raw)

                                                                                    if temp then
                                                                                        return string.format("%d°C", temp)
                                                                                        end

                                                                                        -- hwmon fallback
                                                                                        raw = shell([[
                                                                                            cat /sys/class/hwmon/hwmon*/temp1_input 2>/dev/null | head -1
                                                                                        ]])

                                                                                        temp = tonumber(raw)

                                                                                        if temp then
                                                                                            return string.format("%d°C", temp / 1000)
                                                                                            end

                                                                                            return "N/A"
                                                                                            end)
                                                                                    end
