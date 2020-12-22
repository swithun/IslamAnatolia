// -*- java -*-

function selectAll(name) 
{
	 var checkboxes = document.getElementsByName(name);
	 for (var i = 0; i < checkboxes.length; ++ i) 
		 {
				checkboxes[i].checked = !checkboxes[i].checked;
		 }
}
