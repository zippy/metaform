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

function $CF(cb_class){
	return $$(cb_class).findAll(function(cb) {return cb.checked}).pluck("value");
}

function $RF(rb_class){
	var chosen_element = $$(rb_class).find(function(rb){return rb.checked});
	return (chosen_element != null) ? chosen_element.value : null;
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
function mapCheckboxGroupFollowup(group_name,val,form,func) {
	form.getInputs("checkbox").findAll(function(item) 
	{if ((item.name.indexOf(group_name) === 0) && (item.name.indexOf(val) > -1)) {
		func(item,item.name.replace(group_name,'').replace(val,'').gsub(/[\[\]\[-]/,'').gsub(/[\]]/,''));
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

var indexedItems = Class.create();
indexedItems.prototype = {
	elem_id: 'indexed_presentation',
	self_name: 'i',
	delete_text: 'Delete an item',
	initialize: function () {
		},
	addItem: function(item) {
		var items = $(this.elem_id).childElements();
		var item_id = items.length;
		var element = new Element('li', {id:'item_'+items.length,'class':'presentation_indexed_item',style:'display:none'});
		element.innerHTML = item;
		$(element).appendChild(Element('input',{type:'button',value:this.delete_text,onclick:this.self_name+".removeItem($(this).up())"}));
		$(this.elem_id).appendChild(element);
		Effect.toggle(element,'blind',{duration: .3});
	},
	removeItem: function(item) {
		Effect.toggle(item,'blind',{duration: .5, afterFinish: myCallBackOnFinish});
	}
};

function myCallBackOnFinish(obj){
	var item = obj.element.id;
	$(item).remove();
	var items = $(this.elem_id).childElements();
	items.each(function(i,index) {
		$(i).id = 'item_'+index;
		}
	);
}

function arrayMatch(array,regex){
	for (var index = 0, len = array.length; index < len; ++index) {
	  var fv = array[index];
	  if (fv.match(regex)) {
			return true;
		}
	}
	return false;
}		

function insert_tabs(tab_html,before_css,desired_tab_num,multi) {
	next_tabs = $$(before_css);
    current_tab_num = 0;
	while (current_tab_num < desired_tab_num) {
		this_tab_html = tab_html;
		current_tab_num = current_tab_num + 1;
		if (multi) {
			display_num = current_tab_num + 1;
			this_tab_html = this_tab_html.gsub(/NUM/,' '+display_num).gsub(/INDEX/,display_num);
		}
		next_tabs.invoke('insert',{before:  this_tab_html});
	}
}