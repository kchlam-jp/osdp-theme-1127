<%@page import="java.io.*"%>
<%@page import="java.util.*"%>
<%@page import="java.text.*"%>
<%@page import="hksarg.ccgo.applist.business.*"%>
<%@page import="hksarg.ccgo.applist.util.*"%>
<%@page import="hksarg.ccgo.applist.config.*"%>
<%@page import="hksarg.ccgo.applist.constant.*"%>
<%@page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>

<%
String url = request.getRequestURL().toString();
String uri = request.getRequestURI();
String baseURL = url.substring(8, url.length() - uri.length());
boolean isRemoteAccess = baseURL.indexOf("ccgo")>=0?true:false;
//out.println(baseURL+"/n");
boolean printHeader = false;
int port=request.getServerPort();
	response.setHeader("Cache-Control","no-cache"); //HTTP 1.1
	response.setHeader("Pragma","no-cache"); //HTTP 1.0
	response.setDateHeader ("Expires", 0); //prevents caching at the proxy server
	
	// set parameter
	Hashtable ht = new Hashtable();
	//String DPdnsname = "dp.namit.ccgo.hksarg";
	//String DPdnsname = request.getServerName();

	// Get Solution provider name - osdp
	// String vendor = FileUtil.getConfig("applist.solution.provider");

	// get all the headers
	/**    	
		Enumeration enumber = request.getHeaderNames();

	while (enumber.hasMoreElements()) {

		String name = (String) enumber.nextElement();

		String value = request.getHeader(name);

		if (name.indexOf("x-") != -1) // For Novell Solution only
			name = name.substring(name.indexOf("x-") + 2, name.length());

		ht.put(name.toUpperCase(), value);
	}
		
	*/
	// Test Case
	//http://localhost:8091/applist/applist.jsp?cn=User&SN=cheng&EMPLOYEETYPE=99&DPSTAFFGROUP=1&DPHKID=11121&DPRANKCODE=29

	Enumeration enumber = request.getHeaderNames();

	if (printHeader){
		out.println("Dump Header/n");
		out.println("<table>");
	}
	while (enumber.hasMoreElements()) {

		String name = (String)enumber.nextElement();
    	String value = request.getHeader(name);

    	if ( name.indexOf("x-") != -1  )  // For Novell Solution only
    	  name = name.substring(name.indexOf("x-")+2, name.length());

    	ht.put(name.toUpperCase(), value);
    	if (printHeader){
	    	out.println("<tr>");
	  		out.println("<td>");
	  		out.println(name);
	  		out.println("</td>");
	  		out.println("<td>");
	  		out.println(value);
	  		out.println("</td>");
	  		out.println("/tr");
    	}
	}
	if (printHeader){
		out.println("</table>");
	}

	String serverName = null;
	if (!isRemoteAccess) {
		serverName = FileUtil.getConfig("idp.name.local");
	} else {
		serverName = FileUtil.getConfig("idp.name.remote");
	}
	
	String IDPEntityID=(String)ht.get("Shib-Identity-Provider".toUpperCase());
	String uid=(String)ht.get("uid".toUpperCase());
	String SLO_URL = FileUtil.getConfig("idp.logout.url").replace("{idp.name}",serverName);
	
	String changePasswordURL = FileUtil.getConfig("change_password_url");
	String welcomeURL = "https://"+baseURL;
	
	// Comparison of DPLASTLOGINTIME and DPFAILEDLOGINTIME
	SimpleDateFormat format1 = new SimpleDateFormat("yyyyMMddHHmmss");
	format1.setTimeZone(TimeZone.getTimeZone("GMT"));
	SimpleDateFormat format2 = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss");
	format2.setTimeZone(TimeZone.getTimeZone("Hongkong"));
	String lastLoginTimeStr = (String)ht.get("DPLASTLOGINTIME");
	//out.println("Last Login Time Str ="+lastLoginTimeStr);
	String lastFailLoginTimeStr = (String)ht.get("DPFAILEDLOGINTIME");
	//out.println("Last Failed Login Time Str ="+lastFailLoginTimeStr);
	String passwordExpirationTimeStr = (String)ht.get("PASSWORDEXPIRATIONTIME");
	//out.println("Password Expiration Time Str ="+passwordExpirationTimeStr);
		
	String displayLastLoginTime = null;
	String displayLastFailLoginTime = null;
	String displayPasswordExpirationTime = null;
	Date passwordExpirationTime = null;
	Date lastLoginTime = null;
	Date lastFailLoginTime = null;
    boolean showLastLoginTime = false;
    boolean showLastFailLoginTime = false;
    boolean showPasswordExpirationTime = false;
    long diffDays = 0;
	
	if (passwordExpirationTimeStr != null)
		try {
			passwordExpirationTime = format1.parse(passwordExpirationTimeStr.substring(0,14));
			//out.println("Password Expiration Time = ");
			//out.println(passwordExpirationTime);
		} catch (Exception e){
			e.printStackTrace();
		}		
    if (lastLoginTimeStr != null)
		try {
			lastLoginTime = format1.parse(lastLoginTimeStr.substring(0,14));
			//out.println("Last Login Time = ");
			//out.println(lastLoginTime);
		} catch (Exception e){
			e.printStackTrace();
		}
	if (lastFailLoginTimeStr != null)
		try {
			lastFailLoginTime = format1.parse(lastFailLoginTimeStr.substring(0,14));
			//out.println("Last Failed Login Time = ");
			//out.println(lastFailLoginTime);
		} catch (Exception e){
			e.printStackTrace();
		}
	
	if (passwordExpirationTime !=null)
	{
		Calendar today = Calendar.getInstance();
		Calendar cal = Calendar.getInstance();
		cal.setTime(passwordExpirationTime);
	    long milliseconds1 = today.getTimeInMillis();
	    long milliseconds2 = cal.getTimeInMillis();
	    long diff = milliseconds2 - milliseconds1;
//	    long diffSeconds = diff / 1000;
//	    long diffMinutes = diff / (60 * 1000);
//	    long diffHours = diff / (60 * 60 * 1000);
	    diffDays = diff / (24 * 60 * 60 * 1000);
//	    out.println("Time in days: " + diffDays + " days.");
	    if (diffDays<30){
	    	showPasswordExpirationTime = true;
	    }
	}
	if (lastLoginTime != null){
		showLastLoginTime = true;
		displayLastLoginTime = format2.format(lastLoginTime);
	}
	if (lastLoginTime == null && lastFailLoginTime != null){
		showLastFailLoginTime = true;
		displayLastFailLoginTime = format2.format(lastFailLoginTime);
	}
	if (lastLoginTime != null || lastFailLoginTime !=null){
		if (lastFailLoginTime.compareTo(lastLoginTime)>0){
			showLastFailLoginTime = true;
			displayLastFailLoginTime = format2.format(lastFailLoginTime);
		}
	}
	// end Comparison of DPLASTLOGINTIME and DPFAILEDLOGINTIME
%>
<!DOCTYPE html>
<html><head>
		<meta http-equiv="content-type" content="text/html; charset=UTF-8">
		<META http-equiv="Content-Style-Type" content="text/css">
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width,initial-scale=1.0">
        <title>OSDP Applications List</title>
        <link rel="stylesheet" type="text/css" href="osdp_app_list_files/main.css">
        <link rel="stylesheet" type="text/css" href="osdp_app_list_files/leftmenu.css">
		<link rel="stylesheet" href="osdp_app_list_files/style.css">
		<link rel="stylesheet" href="osdp_app_list_files/jquery-ui.css">
		<link rel="stylesheet" href="osdp_app_list_files/cus.css">
		
		<script src="js/jquery-3.3.1.min.js"></script>
				
		<SCRIPT>
		<!--
		function writeLog(data1, data2, data3, data4){
			$.ajax({
		    	type: "POST",
				url: 'WriteAuditLogServlet',
				data: { 
					uid : data1.toString(), 
					clientIp : data2.toString(), 
					userAgent : data3.toString(), 
					spEntityID : data4.toString() 
				},
				success : function(responseText){
		        }
		    });
		    return true;
		}		

		function launchApp(url)	{
			//Comment out the either One Option
			window.open(url,"SubWindow","width=1024,height=768,resizable=yes"); //Option 1. for pop-up window - parameters updated in version 3.5
			//window.location = url; //Option 2. for same window
		}
		
		$(document).ready(function(){
			var applistUrl = window.location.href;
			var popupReference;
			popupReference = window.open("dp_popup.jsp?applistUrl="+applistUrl+"&welcomeURL=<%=welcomeURL%>"+"&SLOUrl=<%=SLO_URL%>"+"&uid=<%=uid%>"+"&changePasswordURL=<%=changePasswordURL%>","Popup","fullscreen=no,toolbar=no,status=no,menubar=no,scrollbars=no,resizable=no,width=500,height=400");
			popupReference.focus();
		});
		
		// -->
		</SCRIPT>
    </head>
<body>
	<div id="wrapper" class="clearfix">
      <div id="container" class="clearfix">
		<header>
          <img src="osdp_app_list_files/banner_smartcity_1.jpg" alt="Replace or remove this logo" class="header_banner">
		      <img alt="香港特別行政區政府,政府資訊科技總監辦公室" src="osdp_app_list_files/logo-main-tc.png" class="header-logo__long">
        </header>
		<div id="content" class="clearfix">
			<form class="form form--user">
				<div class="container" class="clearfix">
					<div class="inner-content">
						<div class="form__field">
							<div class="form__field-body">
								<div class="form__field-col">
									<h2 class="page-title">Welcome to Departmental Portal Applications List</h2>
								</div>
								<!--
								<div class="form__controller" style="padding-top: 40px;">
									<button type="submit" class="btn btn-common" onclick="">Logout</button>
								</div>
								-->
							</div>
							<p>Hello! <%=(String)ht.get("CN")%></p>
							<%if (showPasswordExpirationTime) {%>
							 	<p style="color:RED">Your password is going to expire in <%=diffDays %> days, please change your password immediately</p>
							<%} %>
							<%if (showLastFailLoginTime) {%>
							 	<p>Last Unsuccessful Login Time : <%=displayLastFailLoginTime %></p>
							<%} %>
							<%if (showLastLoginTime) {%>
							 	<p>Last Login Time : <%=displayLastLoginTime %></p>
							<%} %>
							<p>Please note that unauthorized access is forbidden to access this AppList and application.</p>
						</div>
						<h3>Remote Applications List</h3>
						<table class="table table-bordered table-hover table--user-account" style="width: 802px;">

							<tr>
								<th>Provider</th>
								<th>URL</th>
							</tr>

<%  // Create business object to retrieve a list of remote applications
	MainAppList mainAppList = new MainAppList( ht ,baseURL,port);
	try{
		Vector result_list = mainAppList.getRemoteAppList("crossdomain","production");
		// Vector result_list = XmlLoader.getRemoteAppList(isRemoteAccess);
		for (int i=0; i< result_list.size(); i++) {
			out.println((String)result_list.get(i));
		}
	}catch(Exception e){
		out.println("<tr><td class=\"engSubTitle\">ERROR! "+e.getMessage()+"!</td></tr>");
	}
%>		
<!--
							<tr>
								<td>NOVELLIT_iChain2.3</td>
								<td><a class="btn-edit" href="#">App1</a></td>
							</tr>
-->		
						</table>
						<br>
						<h3>Local Applications List</h3>
						<table class="table table-bordered table-hover table--user-account" style="width: 802px;">
<%
	try{

		// Create business object to retrieve a list of local applications
		Vector local_app_list = mainAppList.getLocalAppList("local");
		// Vector local_app_list = XmlLoader.getLocalAppList(isRemoteAccess);
		for (int i=0; i< local_app_list.size(); i++) {
			out.println((String)local_app_list.get(i));
		}

	}catch(Exception e){ out.println("<tr><td class=\"engSubTitle\">ERROR! "+e.getMessage()+"!</td></tr>"); }
%>
<!--
							<tr>
								<td><a class="btn-edit" href="#">OSDP App1</a></td>
							</tr>
-->		
						</table>
					</div>
				</div>
			</form>
		</div>
      <footer>
        <div class="container container-footer">
			<div class="footer__bottom">
					<div class="footer__logos">
						<a id="wcagLogo" href="http://www.w3.org/WAI/WCAG2AA-Conformance" rel="external" class="footer__logo" title="遵守2A級無障礙圖示，萬維網聯盟（W3C）- 無障礙網頁倡議（WAI） Web Content Accessibility Guidelines 2.0" target="_blank"><img src="osdp_app_list_files/img-footer-logo-1.png" alt="遵守2A級無障礙圖示，萬維網聯盟（W3C）- 無障礙網頁倡議（WAI） Web Content Accessibility Guidelines 2.0"></a>
						<a href="http://www.ipv6forum.com/" rel="external" class="footer__logo" title="IPv6 電腦器材可瀏覽本網站" target="_blank"><img src="osdp_app_list_files/img-footer-logo-2.png" alt="IPv6 電腦器材可瀏覽本網站"></a>
						<a href="https://www.ogcio.gov.hk/tc/our_work/community/web_mobileapp_accessibility/nurturing_expertise/recognition_scheme/index.html" rel="external" class="footer__logo" title="無障礙網頁嘉許計劃" target="_blank"><img src="osdp_app_list_files/img-footer-logo-3.png" alt="無障礙網頁嘉許計劃"></a>
						<a href="http://www.erb.org/md/tc/Main/" rel="external" class="footer__logo" title="僱員再培訓局計劃" target="_blank"><img src="osdp_app_list_files/img-footer-logo-7.png" alt="僱員再培訓局計劃"></a>
						<a href="http://www.caringcompany.org.hk/" rel="external" class="footer__logo" title="caringorganisation 同心展關懷" target="_blank"><img src="osdp_app_list_files/img-footer-logo-4.png" alt="caringorganisation 同心展關懷"></a>
						<a href="http://www.brandhk.gov.hk/index.html" rel="external" class="footer__logo" title="香港品牌形象 - 亞洲國際都會" target="_blank"><img src="osdp_app_list_files/img-footer-logo-5.png" alt="香港品牌形象 - 亞洲國際都會"></a>
					</div>
					<div class="footer__copyright"><span>2018© 政府資訊科技總監辦公室</span><span class="footer__bottom-sp">|</span><span>覆檢日期： </span><span id="revisionDate">27 July 2018</span></div>
			</div>        
		</div>
      </footer>
	</div>
</div>
</body>
</html>