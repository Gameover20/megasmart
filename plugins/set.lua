local function run(msg, matches)
  if matches[1] == 'بگو' then
    if is_momod(msg) then
      local text = matches[2]
      local b = 1

      while b ~= 0 do
      text = text:trim()
      text,b = text:gsub('^+','')
      return text
    end
    else
      return 'نمیگم زوره؟ 😏😏'
   end
 end
end
return {
  description = "Simplest plugin ever!",
  usage = "echo [whatever]: echoes the msg",
  patterns = {
    "^بگو +(.+)$",
  },
  run = run
}
