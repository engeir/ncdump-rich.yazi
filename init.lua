-- NOTE: see https://yazi-rs.github.io/docs/plugins/overview/#previewer as well as
-- https://github.com/yazi-rs/plugins for inspiration.
-- Also: https://github.com/yazi-rs/plugins/blob/main/lsar.yazi/init.lua
M = {}
M.peek = function(self, job)
    job = job or self
    local child, code =
        Command("ncdump-rich"):arg(tostring(job.args)):arg(tostring(job.file.url)):stdout(Command.PIPED):spawn()
    if not child then
        return ya.err("spawn `ncdump-rich` command returns " .. tostring(code))
    end

    local limit = job.area.h
    local i, lines = 0, {}
    repeat
        local next, event = child:read_line()
        if event ~= 0 then
            break
        end

        i = i + 1
        if i > job.skip then
            lines[#lines + 1] = next
        end
    until i >= job.skip + limit

    child:start_kill()
    if job.skip > 0 and i < job.skip + limit then
        ya.manager_emit("peek", { math.max(0, i - limit), only_if = job.file.url, upper_bound = true })
    else
        ya.preview_widgets(job, { ui.Text(lines):area(job.area) })
    end
end
function M:seek(job)
    local units = type(job) == "table" and job.units or job
    job = type(job) == "table" and job or self

    local h = cx.active.current.hovered
    if h and h.url == job.file.url then
        local step = math.floor(units * job.area.h / 10)
        ya.manager_emit("peek", {
            math.max(0, cx.active.preview.skip + step),
            only_if = job.file.url,
        })
    end
end
return M
