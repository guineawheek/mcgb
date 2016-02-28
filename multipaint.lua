multipaint = {}
multipaint.__index = multipaint

setmetatable(multipaint, {
    __call = function(cls, ...)
        return cls.new(...)
    end,
})

function multipaint.new(monitors)
    local self = setmetatable({}, multipaint)
    self.map = monitors
    return self
end

function multipaint:drawPixel(x, y, color)
    for i = 1,#self.map do
        if x >= self.map[i][2][1] and x <= self.map[i][2][2] and
           y >= self.map[i][3][1] and y <= self.map[i][3][2] then
            t = self.map[i][1]

            print(x..','..y.."\r\n")
            term.redirect(t) 
            paintutils.drawPixel(x - self.map[i][2][1], y - self.map[i][3][1], color)
            term.redirect(term.native())
            return
        end
    end
end
