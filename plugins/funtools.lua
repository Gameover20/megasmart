do
--------------------------
function run_bash(str)
    local cmd = io.popen(str)
    local result = cmd:read('*all')
    return result
end
local api_key = nil
local base_api = "https://maps.googleapis.com/maps/api"
function get_latlong(area)
  local api      = base_api .. "/geocode/json?"
  local parameters = "address=".. (URL.escape(area) or "")
  if api_key ~= nil then
    parameters = parameters .. "&key="..api_key
  end
  local res, code = https.request(api..parameters)
  if code ~=200 then return nil  end
  local data = json:decode(res)

  if (data.status == "ZERO_RESULTS") then
    return nil
  end
  if (data.status == "OK") then
    lat  = data.results[1].geometry.location.lat
    lng  = data.results[1].geometry.location.lng
    acc  = data.results[1].geometry.location_type
    types= data.results[1].types
    return lat,lng,acc,types
  end
end
function get_staticmap(area)
  local api        = base_api .. "/staticmap?"
  local lat,lng,acc,types = get_latlong(area)

  local scale = types[1]
  if     scale=="locality" then zoom=8
  elseif scale=="country"  then zoom=4
  else zoom = 13 end

  local parameters =
    "size=600x300" ..
    "&zoom="  .. zoom ..
    "&center=" .. URL.escape(area) ..
    "&markers=color:red"..URL.escape("|"..area)

  if api_key ~=nil and api_key ~= "" then
    parameters = parameters .. "&key="..api_key
  end
  return lat, lng, api..parameters
end


--------------------------
local function clean_msg(extra, suc, result)
  for i=1, #result do
    delete_msg(result[i].id, ok_cb, false)
  end
  if tonumber(extra.con) == #result then
    send_msg(extra.chatid, ''..#result..' messages were deleted', ok_cb, false)
  else
    send_msg(extra.chatid, 'Error Deleting messages', ok_cb, false)
end
end
-----------------------
local function toimage(msg, success, result)
  local receiver = get_receiver(msg)
  if success then
    local file = './data/tophoto/'..msg.from.id..'.jpg'
    print('File downloaded to:', result)
    os.rename(result, file)
    print('File moved to:', file)
    send_photo(get_receiver(msg), file, ok_cb, false)
    redis:del("sticker:photo")
  else
    print('Error downloading: '..msg.id)
    send_large_msg(receiver, 'Failed, please try again!', ok_cb, false)
  end
end
-----------------------
local function tosticker(msg, success, result)
  local receiver = get_receiver(msg)
  if success then
    local file = './data/tosticker/'..msg.from.id..'.webp'
    print('File downloaded to:', result)
    os.rename(result, file)
    print('File moved to:', file)
    send_document(get_receiver(msg), file, ok_cb, false)
    redis:del("photo:sticker")
  else
    print('Error downloading: '..msg.id)
    send_large_msg(receiver, 'Failed, please try again!', ok_cb, false)
  end
end

------------------------
local function get_weather(location)
  print("Finding weather in ", location)
  local BASE_URL = "http://api.openweathermap.org/data/2.5/weather"
  local url = BASE_URL
  url = url..'?q='..location..'&APPID=eedbc05ba060c787ab0614cad1f2e12b'
  url = url..'&units=metric'
  local b, c, h = http.request(url)
  if c ~= 200 then return nil end

   local weather = json:decode(b)
   local city = weather.name
   local country = weather.sys.country
   local temp = 'دمای شهر '..city..' هم اکنون '..weather.main.temp..' درجه سانتی گراد می باشد'
   local conditions = 'شرایط فعلی آب و هوا : '

   if weather.weather[1].main == 'Clear' then
     conditions = conditions .. 'آفتابی☀'
   elseif weather.weather[1].main == 'Clouds' then
     conditions = conditions .. 'ابری ☁☁'
   elseif weather.weather[1].main == 'Rain' then
     conditions = conditions .. 'بارانی ☔'
   elseif weather.weather[1].main == 'Thunderstorm' then
     conditions = conditions .. 'طوفانی ☔☔☔☔'
 elseif weather.weather[1].main == 'Mist' then
     conditions = conditions .. 'مه 💨'
  end

  return temp .. '\n' .. conditions
end
--------------------------
local function calc(exp)
   url = 'http://api.mathjs.org/v1/'
  url = url..'?expr='..URL.escape(exp)
   b,c = http.request(url)
   text = nil
  if c == 200 then
    text = 'Result = '..b
  elseif c == 400 then
    text = b
  else
    text = 'Unexpected error\n'
      ..'Is api.mathjs.org up?'
  end
  return text
end
--------------------------
function run(msg, matches)
------------------------
 if matches[1] == "معنی" then
 http = http.request('http://api.vajehyab.com/v2/public/?q='..URL.escape(matches[2]))
   data = json:decode(http)
	return 'واژه : '..(data.data.title or data.search.q)..'\n\nترجمه : '..(data.data.text or '----' )..'\n\nمنبع : '..(data.data.source or '----' )..'\n\n'..(data.error.message)
end
--------------------------
if matches[1] == "calc" and matches[2] then
    if msg.to.type == "user" then
       return
       end
    return calc(matches[2])
end
--------------------------
if matches[1] == 'وضعیت' then
    city = matches[2]
  local wtext = get_weather(city)
  if not wtext then
    wtext = 'مکان وارد شده صحیح نیست'
  end
  return wtext
end
---------------------
if matches[1] == 'زمان' then
local url , res = http.request('http://api.gpmod.ir/time/')
if res ~= 200 then
 return "Api Eror"
  end
  local colors = {'blue','green','yellow','magenta','Orange','DarkOrange','red'}
  local fonts = {'mathbf','mathit','mathfrak','mathrm'}
local jdat = json:decode(url)
local url = 'http://latex.codecogs.com/png.download?'..'\\dpi{600}%20\\huge%20\\'..fonts[math.random(#fonts)]..'{{\\color{'..colors[math.random(#colors)]..'}'..jdat.ENtime..'}}'
local file = download_to_file(url,'time.webp')
send_document(get_receiver(msg) , file, ok_cb, false)

end
--------------------
if matches[1] == 'ویس' then
 local text = matches[2]

  local b = 1

  while b ~= 0 do
    textc = text:trim()
    text,b = text:gsub(' ','.')


  if msg.to.type == 'user' then
      return nil
      else
  local url = "http://tts.baidu.com/text2audio?lan=en&ie=UTF-8&text="..textc
  local receiver = get_receiver(msg)
  local file = download_to_file(url,'Self-Bot.mp3')
 send_audio('channel#id'..msg.to.id, file, ok_cb , false)
end
end
end
 --------------------------
   if matches[1] == "tr" and is_sudo(msg) then
     url = https.request('https://translate.yandex.net/api/v1.5/tr.json/translate?key=trnsl.1.1.20160119T111342Z.fd6bf13b3590838f.6ce9d8cca4672f0ed24f649c1b502789c9f4687a&format=plain&lang='..URL.escape(matches[2])..'&text='..URL.escape(matches[3]))
     data = json:decode(url)
   return 'زبان : '..data.lang..'\nترجمه : '..data.text[1]
end

-----------------------
if matches[1] == 'لینک کوچک' then
 local yon = http.request('http://api.yon.ir/?url='..URL.escape(matches[2]))
  local jdat = json:decode(yon)
  local bitly = https.request('https://api-ssl.bitly.com/v3/shorten?access_token=f2d0b4eabb524aaaf22fbc51ca620ae0fa16753d&longUrl='..URL.escape(matches[2]))
  local data = json:decode(bitly)
  local yeo = http.request('http://yeo.ir/api.php?url='..URL.escape(matches[2])..'=')
  local opizo = http.request('http://api.gpmod.ir/shorten/?url='..URL.escape(matches[2])..'&username=mersad565@gmail.com')
  local u2s = http.request('http://u2s.ir/?api=1&return_text=1&url='..URL.escape(matches[2]))
  local llink = http.request('http://llink.ir/yourls-api.php?signature=a13360d6d8&action=shorturl&url='..URL.escape(matches[2])..'&format=simple')
    return ' 🌐لینک اصلی :\n'..data.data.long_url..'\n\nلینکهای کوتاه شده با 6 سایت کوتاه ساز لینک : \n》کوتاه شده با bitly :\n___________________________\n'..data.data.url..'\n___________________________\n》کوتاه شده با yeo :\n'..yeo..'\n___________________________\n》کوتاه شده با اوپیزو :\n'..opizo..'\n___________________________\n》کوتاه شده با u2s :\n'..u2s..'\n___________________________\n》کوتاه شده با llink : \n'..llink..'\n___________________________\n》لینک کوتاه شده با yon : \nyon.ir/'..jdat.output
end
------------------------
 local receiver = get_receiver(msg)
    local group = msg.to.id
    if msg.reply_id then
       if msg.to.type == 'document' and redis:get("sticker:photo") then
        if redis:set("sticker:photo", "waiting") then
        end
       end

      if matches[1]:lower() == 'عکس' then
     redis:get("sticker:photo")

        load_document(msg.reply_id, toimage, msg)
    end
end
------------------------
	    local receiver = get_receiver(msg)
    local group = msg.to.id
    if msg.reply_id then
       if msg.to.type == 'photo' and redis:get("photo:sticker") then
        if redis:set("photo:sticker", "waiting") then
        end
       end
      if matches[1]:lower() == 'استیکر' then
     redis:get("photo:sticker")
        load_photo(msg.reply_id, tosticker, msg)
    end
end
------------------------
if matches[1] == "delplugin" and is_sudo(msg) then
	      if not is_sudo(msg) then
             return "You Are Not Allow To Delete Plugins!"
             end
        io.popen("cd plugins && rm "..matches[2]..".lua")
        return "Delete plugin successful "
     end
---------------
     if matches[1] == "استیکر " then
local eq = URL.escape(matches[2])
local w = "500"
local h = "500"
local txtsize = "150"
local txtclr = "ff2e4357"
if matches[3] then
  txtclr = matches[3]
end
if matches[4] then
  txtsize = matches[4]
  end
  if matches[5] and matches[6] then
  w = matches[5]
  h = matches[6]
  end
  local url = "https://assets.imgix.net/examples/clouds.jpg?blur=150&w="..w.."&h="..h.."&fit=crop&txt="..eq.."&txtsize="..txtsize.."&txtclr="..txtclr.."&txtalign=middle,center&txtfont=Futura%20Condensed%20Medium&mono=ff6598cc"

  local receiver = get_receiver(msg)
local  file = download_to_file(url,'text.webp')
 send_document('channel#id'..msg.to.id, file, ok_cb , false)
end
---------------
     if matches[1] == "عکس" then
local eq = URL.escape(matches[2])
local w = "500"
local h = "500"
local txtsize = "150"
local txtclr = "ff2e4357"
if matches[3] then
  txtclr = matches[3]
end
if matches[4] then
  txtsize = matches[4]
  end
  if matches[5] and matches[6] then
  w = matches[5]
  h = matches[6]
  end
  local url = "https://assets.imgix.net/examples/clouds.jpg?blur=150&w="..w.."&h="..h.."&fit=crop&txt="..eq.."&txtsize="..txtsize.."&txtclr="..txtclr.."&txtalign=middle,center&txtfont=Futura%20Condensed%20Medium&mono=ff6598cc"

  local receiver = get_receiver(msg)
local  file = download_to_file(url,'text.jpg')
 send_photo('channel#id'..msg.to.id, file, ok_cb , false)
end
--------------

  if matches[1] == 'اذان' then
	city = 'Tehran'
	end
  local hash = 'usecommands:'..msg.from.id..':'..msg.to.id
  redis:incr(hash)
  local receiver	= get_receiver(msg)
  local city = matches[2]
	local lat,lng,url	= get_staticmap(city)

	local dumptime = run_bash('date +%s')
	local code = http.request('http://api.aladhan.com/timings/'..dumptime..'?latitude='..lat..'&longitude='..lng..'&timezonestring=Asia/Tehran&method=7')
	local jdat = json:decode(code)
	local data = jdat.data.timings
	local text = '🌐 شهر: '..city
	  text = text..'\n💠 اذان صبح: '..data.Fajr
	  text = text..'\n💠 طلوع آفتاب: '..data.Sunrise
	  text = text..'\n💠 اذان ظهر: '..data.Dhuhr
	  text = text..'\n💠 غروب آفتاب: '..data.Sunset
	  text = text..'\n💠 اذان مغرب: '..data.Maghrib
	  text = text..'\n💠 عشاء : '..data.Isha
	  text = text..'\n\n@Smart_TG'
	if string.match(text, '0') then text = string.gsub(text, '0', '۰') end
	if string.match(text, '1') then text = string.gsub(text, '1', '۱') end
	if string.match(text, '2') then text = string.gsub(text, '2', '۲') end
	if string.match(text, '3') then text = string.gsub(text, '3', '۳') end
	if string.match(text, '4') then text = string.gsub(text, '4', '۴') end
	if string.match(text, '5') then text = string.gsub(text, '5', '۵') end
	if string.match(text, '6') then text = string.gsub(text, '6', '۶') end
	if string.match(text, '7') then text = string.gsub(text, '7', '۷') end
	if string.match(text, '8') then text = string.gsub(text, '8', '۸') end
	if string.match(text, '9') then text = string.gsub(text, '9', '۹') end
	return text
end
end
return {
patterns = {
   "^(وضعیت) (.*)$",
   "^[!/](calc) (.*)$",
   "^(زمان)$",
   "^(ویس) +(.*)$",
   "^[!/]([Tt]r) ([^%s]+) (.*)$",
   "^(معنی) (.*)$",
   "^(لینک کوچک) (.*)$",
   "^(استیکر)$",
   "^(عکس)$",
     "^(عکس) (.+)$",
    "^(استیکر) (.+)$",
    "^(اذان) (.*)$",
    "^(اذان)$",
   "%[(document)%]",
   "%[(photo)%]",


 },
run = run,
}
