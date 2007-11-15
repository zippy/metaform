function $XF(el, radioGroup) {
	if($(el).type == 'radio') {
		var el = $(el).form;
		var radioGroup = $(el).name;
	} else if ($(el).tagName.toLowerCase() != 'form') {
		return false;
	}
	return $F($(el).getInputs('radio', radioGroup).find(
		function(re) {return re.checked;}
	));
}

function $CF(el){
	return getCheckboxGroupValue(el,$('metaForm'))
}

function $RF(el){
	return getRadioGroupValue(el,$('metaForm'))
}

function $DF(name){
	var d = new Date($F(name+'_month') + "/" + $F(name+'_day')  + "/" + $F(name+'_year'));
	return (d == "Invalid Date") ? null : d;
}

function getRadioGroupValue(radioGroupName,form) {
	var checked_element = form.getInputs('radio', radioGroupName).find(function(re) {return re.checked;});
	return (checked_element != null) ? $F(checked_element) : null;
}

function getCheckboxGroupValue(checkboxGroupName,form) {
	return form.getInputs("checkbox").findAll(
		function(item) { 
			if (item.name.indexOf(checkboxGroupName) === 0) {
				return item.checked; 
			}
	}).pluck("value");
}

function setCheckboxGroup(checkboxGroupName,form,value) {
	form.getInputs("checkbox").findAll(function(item)
	{ if (item.name.indexOf(checkboxGroupName) === 0) {
		item.checked = value;
	} });
}
function mapCheckboxGroup(checkboxGroupName,form,func) {
	form.getInputs("checkbox").findAll(function(item)
	{ if (item.name.indexOf(checkboxGroupName) === 0) {
		func(item,item.name.replace(checkboxGroupName,'').gsub(/[\[\]]/,''));
	} });
}

function oc(a)
{
  var o = {};
  for(var i=0;i<a.length;i++)
  {
    o[a[i]]='';
  }
  return o;
}

function submitAndRedirect(url)
{
	if ($('metaForm')) {
		$('_redirect_url').value = url;
		$('metaForm').submit();
		return false;
	}
	else {
		location.href = url;
		return false;
	}
}

var WidgetWatcher = Class.create();
WidgetWatcher.prototype = {
	initialize: function(widget,my_function) {
		this.widget = $(widget);
		this.my_function = my_function;
		this.widget.onclick = this.do_onclick.bindAsEventListener(this);
	},	
	
	do_onclick: function(evt) {
		this.my_function();
	}
};