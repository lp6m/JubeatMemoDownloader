require 'hpricot'
require 'open-uri'
require 'kconv'


def CreateMainURL #これは普段は使わない 譜面リンクが存在するURLを取得するためのもの（新しくできたときに取得可能）
	doc = Hpricot( open("http://www14.atwiki.jp/jubeat_memo/").read)
	(doc/:a).each do |link|
		if(link.inner_html.include?("譜面")) then
		  puts "#{link.inner_html} → #{link[:href]}"
		  	File.open("url.txt","w") do |file|
				file.write(link.inner_html)
				file.write("\n")
				file.write(link[:href].("Shift_JIS","UTF-8"))
				file.write("\n")
			end
		end
	end
end

def integer_string?(str)
  Integer(str)
  true
rescue ArgumentError
  false
end

def HumenGetfromID(id) #指定されたidの譜面データを取得する
	#LoadURL
	url = "http://www14.atwiki.jp/jubeat_memo/pages/" + id.to_s + ".html"
	doc = Hpricot( open(url).read )
	title_sub = doc.search('meta[@name=description]').to_html

	#title,bpm,levelを処理する
	titlepos = title_sub.index("jubeat_memo")+13
	lvpos = title_sub.index("- LV:")-2
	notepos = title_sub.index("Notes")-1
	bpmpos = title_sub.index("BPM:")


	title_st = title_sub.slice(titlepos..lvpos).strip.gsub('.','_')
	title_st_m = title_sub.slice(titlepos..lvpos-5).strip.gsub('.','_')
	level_st = title_sub.slice(lvpos+7..notepos).strip
	bpm_st = title_sub.slice(bpmpos+4..bpmpos+7).strip
	

	#bpmが書かれていないもしくは?などが含まれているときは別のフォルダに保存する
	file_name=""
	if (!integer_string?(bpm_st)) then
		puts "Unknown BPM!"
		file_name = "fumen(error)/"
		File.open("bpm_error_log.txt","a") do |file|
			file.write(id.to_s+"\n")
		end
	else
		file_name = "fumen/"
		file_name2 = "fumen2/"
	end
	diff = 3
	if(title_st.include?("ADV")) then diff = 2 end
	if(title_st.include?("BSC")) then diff = 1 end
	
	puts "Title:"+title_st
	puts "Level:"+level_st+"BPM:"+bpm_st

	successf = false
	#譜面データの取得
	(doc/".plugin_aa").each do |link|
		data = link.inner_html
		er_key = '<br />'
		file_name += (title_st+".txt")#memo1
		file_name2 += (title_st+".txt")#memo2

		File.open(file_name,"w") do |file|
			tmp1 = "t="+bpm_st+"\n"+"m=\""+title_st_m+".mp3\"\n"
			tmp2 = "#diff="+diff.to_s+"\n#lev="+level_st+"\n#title=\""+title_st_m+"\"\n#jacket=\"" + title_st_m + ".jpg\"\n"
			file.write(tmp1)			
			file.write("o=0\n\n") #offsetは後で手動調整
			file.write(tmp2)
			file.write("#memo1\n")
			file.write(data.gsub(er_key, "\n"))
			# file.write(data.encode("Shift_JIS",:undef => :replace, :replace => "*").gsub(er_key, "\n"))
		end
		File.open(file_name2,"w") do |file|
			tmp1 = "t="+bpm_st+"\n"+"m=\""+title_st_m+".mp3\"\n"
			tmp2 = "#diff="+diff.to_s+"\n#lev="+level_st+"\n#title=\""+title_st_m+"\"\n#jacket=\"" + title_st_m + ".jpg\"\n"
			file.write(tmp1)			
			file.write("o=0\n\n") #offsetは後で手動調整
			file.write(tmp2)
			file.write("#memo2\n")
			file.write(data.gsub(er_key, "\n"))
			# file.write(data.encode("Shift_JIS",:undef => :replace, :replace => "*").gsub(er_key, "\n"))
		end
		puts "Download Completed! id:" + id.to_s
		successf = true
		File.open("success_log.txt","a") do |file|
			file.write(id.to_s+"\n")
		end
	end
	if successf == false then 
		puts "Download Failed id:" + id.to_s #書式が違うとこちらにくる
		File.open("dl_fail_log.txt","a") do |file|
			file.write(id.to_s+"\n")
		end
	end
rescue NoMethodError
	puts "NoMethod / Access Error!"
	File.open("ac_fail_log.txt","a") do |file|
	file.write(id.to_s+"\n")
	end

rescue NameError
	puts "HTTPError (too many access?)"
	File.open("http_error_log.txt","a") do |file|
	file.write(id.to_s+"\n")
	end	
end


#url.txtにあるURLを列挙してそのなかのリンクをすべて試す
cnt = 1
elist=[]
slist=[]
File.open("escape.txt", "r") do|file|
 while list = file.gets
 	elist.push(list.to_s.chomp)
 end
end

if FileTest.exist?("success_log.txt.txt") then
	File.open("success_log.txt","r") do |file|
 		while list = file.gets
 			slist.push(list.to_s.chomp)
 		end
	end
end

File.open("url.txt","r") do|file|
  while line = file.gets
    puts line
    if(cnt%2==0) then
		doc = Hpricot( open(line).read)
		(doc/:a).each do |link|
			url = link[:href].to_s
			if(url.include?("http://www14.atwiki.jp/jubeat_memo/pages/")&&(!url.include?("pdf"))) then
				#puts "#{link.inner_html} → #{link[:href]}"
				puts url
				id = url.gsub("http://www14.atwiki.jp/jubeat_memo/pages/","").delete!(".html")
				puts id
				if(integer_string?(id)&&(!elist.include?(id.to_s))&&(!slist.include?(id.to_s))) then
					HumenGetfromID(id)
				end
			end
		end
    end
    cnt+=1
  end
end