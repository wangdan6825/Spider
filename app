package com.chenmao.download;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.sql.Date;
import java.sql.SQLException;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import us.codecraft.webmagic.Page;
import us.codecraft.webmagic.Site;
import us.codecraft.webmagic.Spider;
import us.codecraft.webmagic.downloader.HttpClientDownloader;
import us.codecraft.webmagic.processor.PageProcessor;
import us.codecraft.webmagic.proxy.Proxy;
import us.codecraft.webmagic.proxy.SimpleProxyProvider;

public class app implements PageProcessor {
	
	
	//抓取网站的相关配置，包括编码、抓取间隔、重试次数等
	private Site site = Site.me().setRetryTimes(3)
			.setUserAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/69.0.3497.100 Safari/537.36")
			.setSleepTime(100);
	private static List<String> exists;
	private static String province="湖北省";
	private static String city="武汉";
	private static String cityid;
	private static int index=1;
	private static Date update_at;//页面刷新的时间
	private static Date update_time;//工作更新的时间
	private static String name;
	private static String company;
	private static String district;
	private String address;
	private static float salary;
	private Job job;

	public Site getSite() {
		return site;
	}

	public void process(Page page) {

		if(page.getUrl().toString().startsWith("https://jobs.51job.com/")){
				
			Calendar c=Calendar.getInstance();
			int year=c.get(Calendar.YEAR);
			int month=c.get(Calendar.MONTH)+1;
			int day=c.get(Calendar.DAY_OF_MONTH);
			String dateString=year+"-"+month+"-"+day;
			SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");  
			java.util.Date d=null;
			try {
				d=sdf.parse(dateString);
			} catch (ParseException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
			java.sql.Date update_at=new java.sql.Date(d.getTime());
			System.out.println("最后更新时间:"+update_at);			


			try{
				
				String html=page.getRawText();
				//System.out.println("进入详情页面");

				File f = new File("E:\\webmagic\\"+province+"\\"+city+"\\"+index+".html");
				index++;
				String file_location="E:\\webmagic\\湖北省\\"+city+"\\"+index;
				//System.out.println(file_location);
				OutputStreamWriter write = new OutputStreamWriter(new FileOutputStream(f,false), "gbk");
				BufferedWriter writer = new BufferedWriter(write);				
				writer.write(html);
				writer.close();

				//职位名称name
				String name=page.getHtml().xpath("//div[@class='cn']/h1/@title").get();
				System.out.println("职位名称："+name);
				//月薪salary
				String money=page.getHtml().xpath("//div[@class='cn']/strong").get();
				String Salary=money.substring(8, money.length()-9);
				String num=Salary.substring(0,Salary.length()-3);
				String s=Salary.substring(Salary.length()-3,Salary.length());
				//System.out.println("s:"+s);
				String[] n=num.split("-");
				String a=n[0].toString();
				String b=n[1].toString();
				float low=Float.parseFloat(a);
				float high=Float.parseFloat(b);
			    float salary=(low+high)/2;
			    if(s.contains("万/月")) {
					salary*=10000;
				}if(s.contains("千/月")) {
					salary*=1000;
				}if(s.contains("万/年")) {
					salary=salary*10000/12;
				}
				System.out.println("月薪："+salary);
				
				
				
				//发布公司company
				String company=page.getHtml().xpath("//p[@class='cname']/a/@title").get();
				System.out.println("发布公司："+company);

				//公司具体位置address
				String Address=page.getHtml().xpath("/html/body/div[3]/div[2]/div[3]/div[2]/div/p").get();
				String address1=Address.replaceAll("[^\\u4e00-\\u9fa5]", "");
				String address=address1.replaceAll("上班地址", "");
				System.out.println("公司具体位置："+address);

				//工作地点、发布时间
				String str=page.getHtml().xpath("//p[@class='msg ltype']/@title").get();
				String[] strs=str.trim().split("  |  ", 10);
				String district=strs[0].substring(0, 2);
				System.out.println("工作地点："+district);
				if(strs[4].contains("人")) {
//					System.out.println("招聘人数："+strs[4]);
					String string1=strs[6];
					String string=string1.replace("发布", "");
					String time="2018-"+string;
					Date update_time = parseDate(time);
					System.out.println("发布时间:"+update_time);	
				}else {
					String string1=strs[8];
					String string=string1.replace("发布", "");
					String time="2018-"+string;
					Date update_time = parseDate(time);
					System.out.println("发布时间:"+update_time);	
				}
				          	
							
			} catch (IOException e) {
				e.printStackTrace();
			}
			

		} else { 

			//System.out.println("进入首页");
			String city=page.getHtml().xpath("//div[@class='txt pointer']/input/@value").get();
			//System.out.println("城市："+city);
			List<String> dates = page.getHtml().xpath("//span[@class='t5']/text()").all();
			//System.out.println(dates);
			List<String> links = page.getHtml().xpath("//div[@class='el']/p/span/a/@href").all();			
			//System.out.println(links);
			page.addTargetRequests(links);

			//新建文件夹
			File file=new File("E:\\webmagic\\"+province+"\\" + city);
			if(!file.exists()){//如果文件夹不存在
				file.mkdir();//创建文件夹
			}
			try{
				//如果文件夹下没有url.txt就会创建该文件
				BufferedWriter bw=new BufferedWriter(new FileWriter("E:\\webmagic\\"+province+"\\"+city+"\\url.txt", true));
				for(String link : links){
					if(link.contains("https://jobs.51job.com/")){
						bw.write(link+"\n");
						exists.add(link);
					}}
				bw.flush();
				bw.close();
			} catch (IOException e) {
				e.printStackTrace();
			}
		}
	}


	//String 类型的时间转Date类型（java.sql.Date）
	public static Date parseDate(String date) {
		
			String[] info = date.split("-");
			int year = Integer.parseInt(info[0]);
			int month = Integer.parseInt(info[1]);
			int day = Integer.parseInt(info[2]);
			Calendar calendar = Calendar.getInstance();
			calendar.set(Calendar.YEAR, year);
			calendar.set(Calendar.MONTH, month-1);
			calendar.set(Calendar.DAY_OF_MONTH, day);
			return new Date(calendar.getTimeInMillis());
	}



	public static String delHtmlTag(String htmlStr) {
		String regEx_html = "<[^>]+>"; // 定义HTML标签的正则表达式
		String regEx_space = "\\s*|\t|\r|\n";//定义空格回车换行符
		Pattern p_html = Pattern.compile(regEx_html, Pattern.CASE_INSENSITIVE);  
		Matcher m_html = p_html.matcher(htmlStr);  
		htmlStr = m_html.replaceAll(""); // 过滤html标签
		Pattern p_space = Pattern.compile(regEx_space, Pattern.CASE_INSENSITIVE);  
		Matcher m_space = p_space.matcher(htmlStr);  
		htmlStr = m_space.replaceAll(""); // 过滤空格回车标签  
		return htmlStr.trim(); // 返回文本字符串  
	}

	public static void main(String[] args) throws IOException{
		
		Map mapcity = new HashMap<String, String>();
		BufferedReader reader = new BufferedReader(new FileReader("E:\\File\\city.txt"));
		String line=null;
		while((line = reader.readLine()) != null){
			String[] split = line.split(":");
			String num = split[0].substring(1, split[0].length()-1);
			String name = split[1].substring(1, split[1].length()-2);
			mapcity.put(name, num);
		}		
		reader.close();
		cityid=mapcity.get(city).toString();


		Map mapprovince = new HashMap<String, String>();
		BufferedReader br=new BufferedReader(new FileReader("E:\\File\\province.txt"));
		String lines=null;
		while((lines=br.readLine())!=null){
			String[] split=lines.split("：");
			String proname=split[0].substring(0, split[0].length());
			String cities=split[1].substring(0, split[1].length());
			mapprovince.put(proname, cities);
		}
		br.close();
		String citynum=mapprovince.get(province).toString();
		System.out.println(citynum);


		exists = new ArrayList<String>();
		FileInputStream fis;
		try {
			fis = new FileInputStream("E:\\webmagic\\"+province+"\\"+city+"\\url.txt");
			BufferedReader breader = new BufferedReader(new InputStreamReader(fis));
			try {
				String l=null;
				while ((l = breader.readLine()) != null) {
					exists.add(l);
				}
			} catch (IOException e) {
				e.printStackTrace();
			}
		} catch (FileNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

		HttpClientDownloader httpClientDownloader = new HttpClientDownloader();
		httpClientDownloader.setProxyProvider(SimpleProxyProvider.from(
				new Proxy("120.92.74.189",3128)
				,new Proxy("121.49.110.65",8888)));

		for(int i=1;i<=1;i++){
			Spider.create(new app())
			.addUrl("https://search.51job.com/list/"+cityid+",000000,0000,32,9,99,%2B,2,"+i+".html?lang=c&stype=1&postchannel=0000&workyear=99&cotype=99&degreefrom=99&jobterm=99&companysize=99&lonlat=0%2C0&radius=-1&ord_field=0&confirmdate=9&fromType=&dibiaoid=0&address=&line=&specialarea=00&from=&welfare=")
			.thread(5)
			.start();		
		}
	}
}
