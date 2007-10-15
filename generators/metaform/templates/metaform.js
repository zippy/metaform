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

function getRadioGroupValue(radioGroupName,form) {
	return $F(form.getInputs('radio', radioGroupName).find(
		function(re) {return re.checked;}
	));
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

function oc(a)
{
  var o = {};
  for(var i=0;i<a.length;i++)
  {
    o[a[i]]='';
  }
  return o;
}