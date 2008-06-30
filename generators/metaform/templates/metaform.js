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

function $TF(name){
	var hours = parseInt($F(name+'_hours'));
	if (isNaN(hours)) {hours=0};
	if ($F(name+'_am_pm') == 'pm') {hours = hours + 12};
	var minutes = parseInt($F(name+'_minutes'));
	if (isNaN(minutes)) {minutes=0};
	var d = new Date("0/0/0 "+ hours + ':' + minutes);
	return (d == "Invalid Date") ? null : d;
}

function $FTF(name){
    var first_box = parseFloat($F(name+'_first_box'));
    var second_box = parseFloat($F(name+'_second_box'));
	if (isNaN(first_box)) {first_box=0};
	if (isNaN(second_box)) {second_box=0};
	return first_box * parseFloat($F(name+'_factor')) + second_box;
}

function $TIF(name){
    var hours = parseFloat($F(name+'_hours'));
    var minutes = parseFloat($F(name+'_minutes'));
	if (isNaN(hours)) {hours=0};
	if (isNaN(minutes)) {minutes=0};
	return hours * 60 + minutes;
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

function oc(a) {
	var o = {};
	for(var i=0;i<a.length;i++) {
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
		var element = new Element('li', {'class':'presentation_indexed_item',style:'display:none'});
		var presentation = this;
		element.innerHTML = item;
		var other_element = new Element('input',{type:'button',value:this.delete_text,'class':'float_right'});
		other_element.onclick = function (evt) {
				presentation.removeItem($(this).up());
			};
		$(element).appendChild(other_element);
		$(element).appendChild(Element('div', {'class':'clear'}));
		$(this.elem_id).appendChild(element);
		Effect.toggle(element,'blind',{duration: .3});
	},
	removeItem: function(item) {
		Effect.toggle(item,'blind',{duration: .5, afterFinish: myCallBackOnFinish});
	}

};

function myCallBackOnFinish(obj){
	var item = obj.element.remove();
}

function arrayMatch(array,regex){
	for (var index = 0, len = array.length; index < len; index++) {
	  var fv = array[index];
	  if (fv.match(regex)) {
			return true;
		}
	}
	return false;
}

function insert_tabs(tab_html,anchor_css,before_anchor,default_anchor_css,desired_tab_num,multi) {
	next_tabs = $$(anchor_css);
	// If your anchor tab isn't there, then put the tab before the default tab.  
	//If that's not there, use the last tab in the group.
	if (next_tabs.length == 0){
		before_anchor = true;
		next_tabs = $$(default_anchor_css);
		if (next_tabs.length == 0) {
			$$(".tabs ul").each(function(tab_ul) {
		  		next_tabs.push(tab_ul.childElements().last());
			});
		}
	}
	current_tab_num = 0;
	while (current_tab_num < desired_tab_num) {
		this_tab_html = tab_html;
		current_tab_num = current_tab_num + 1;
		if (multi) {
			display_num = current_tab_num + 1;
			this_tab_html = this_tab_html.gsub(/NUM/,' '+display_num).gsub(/INDEX/,display_num);
		}
		before_anchor ? next_tabs.invoke('insert',{before:  this_tab_html}) : next_tabs.invoke('insert',{after:  this_tab_html});
		
	}
}

function update_cbgf_hash(followup_id,values) {
	$$('.'+followup_id).each(function(s) {
		var the_value = s.value;
		var value_string = ""
		$$('#' + followup_id + '_' + the_value + ' input').find(function(c){if (c.checked) value_string = value_string + c.value});
		values.set(the_value,value_string);
	});
	
}

function update_date(write_date,read_date) {
	$('record_'+write_date+'_month').value = $F('record_'+read_date+'_month');
	$('record_'+write_date+'_day').value = $F('record_'+read_date+'_day');
	$('record_'+write_date+'_year').value = $F('record_'+read_date+'_year');
}