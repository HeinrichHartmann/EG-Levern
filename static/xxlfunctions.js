var adminOpenWindowWidth=900;
var adminOpenWindowHeight=650;

function keyhandler(sender) {
		if (window.event.keyCode == 13) {
				//senderName = document.getElementById(sender).name;
				document.getElementById(sender).focus();
				//__doPostBack(senderName,'');
		}	
}

function keyhandler2(sname) {
	if (window.event.keyCode == 13) {				
			__doPostBack(sname,'');					
			event.returnValue=false;
		}				
}
function keyhandler3() {
	if (window.event.keyCode == 13) {
		window.event.keyCode = 0;
		return false;
	}
}
	
function opencontentwin(url,target,params) {
	var newwin = window.open(url,target,params);
	newwin.focus();
}

function openOEM(mid, mdefid, itemid, lang, target)
{
	var params = "height=650,width=900,status=off,menu=off,toolbar=off";
	var url = baseurl + "/contentxxl/admin/objecteditmanager/objecteditmanager.aspx?";
	url +=  "mid="+ mid;
	url += "&itemid=" + itemid;
	url += "&mdefid=" + mdefid; 
	url += "&lang=" + lang;
	opencontentwin(url, target, params);								
}

function selectObject(mdefid)
{
	var params = "center:yes;dialogWidth:900px;dialogHeight:650px;status:no;resizible:yes" ;
	var url = baseurl + "/contentxxl/admin/ObjectBrowser/ObjectBrowser.aspx?";
	if (mdefid==null)
		mdefid = 0;
	url += "&selmdefid=" + mdefid; 
	url += "&selector=1";
	return window.showModalDialog(url,"sel_obj",params);
}