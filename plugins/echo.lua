local function run(msg, matches)
  if matches[1] == 'بگو' and matches[2] == 'اخراج من' or 'خروج' or 'خارج' or 'kickme' then
    return 'نمیگم زوره؟ 😏😏'
  else
  local text = matches[2]
  local b = 1

  while b ~= 0 do
    text = text:trim()
    text,b = text:gsub('^+','')
  end
  return text
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
