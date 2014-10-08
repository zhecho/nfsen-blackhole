<?php
/*
 * Frontend plugin: blackHole
 *
 * Required functions: blackHole_ParseInput and blackHole_Run
 *
 */

/* 
 * blackHole_ParseInput is called prior to any output to the web browser 
 * and is intended for the plugin to parse possible form data. This 
 * function is called only, if this plugin is selected in the plugins tab. 
 * If required, this function may set any number of messages as a result 
 * of the argument parsing.
 * The return value is ignored.
 */
function blackHole_ParseInput( $plugin_id ) {

//	SetMessage('error', "Error set by blackHole plugin!");
//	SetMessage('warning', "Warning set by blackHole plugin!");
//	SetMessage('alert', "Alert set by blackHole plugin!");
	//SetMessage('info', "Info set by blackHole plugin!");
	//SetMessage('info', "$catfile");

} // End of blackHole_ParseInput

/*
 * This function is called after the header and the navigation bar have 
 * are sent to the browser. It's now up to this function what to display.
 * This function is called only, if this plugin is selected in the plugins tab
 * Its return value is ignored.
 */
function blackHole_Run( $plugin_id ) {

	//print "<h3>Hello I'm the blackHole plugin with id $plugin_id</h3>\n";
	//SetMessage('info', "Info set by blackHole plugin!");
	// list blackhole file prefixes ...
	$actionErr= $action = "";
	$command = 'blackHole::list_black_hole_prefixes';
	
	print "Query backend plugin for function <b>$command</b><br>\n";
	// vars
	$process_form = array();
	$process_form['pref'] = '';
	$prefix_Err = $prefix_delErr = '';
	$prefix_add = $prefix_del = '';
	
	// one array
	// prepare arguments
	$opts = array();
	$opts['action'] = "list";
	$opts['prefix'] = "fake_prefix";
    	$out_list = nfsend_query($command, $opts);
	//var_dump($out_list);
	//var_dump($opts);
	// get result
   	if ( !is_array($out_list) ) {
        	SetMessage('error', "Error calling backend plugin");
		print "AAAAAAA ";
        	return FALSE;
    	}
	//$iplist = explode(",",$out_list[0],5) ;
	//$iplist = $out_list;
	//var_dump($string);
	//print "Backend reported: <b>prefix: $string</b><br>\n";
	//print "Backend reported: <b>IPlist: $iplist[0]</b><br>\n";
	

	function test_input($data) {
	   $data = trim($data);
	   $data = stripslashes($data);
	   $data = htmlspecialchars($data);
	   return $data;
	}
?>
	<table border="1">
	<tr>
	  <th>UnixTime</th>
	  <th>Prefix</th>
	  <th>Community</th>
	  <th>Next Hop</th>
	  <th>LocalPref</th>
	  <th>Neighbor</th>
	</tr>
	<?php foreach ($out_list as $order): 
		$argum = explode (',', $order[0],5);	
	?>
	  <tr>
	    <td><?php echo $argum[0] ? $argum[0] : null; ?></td>
	    <td><?php echo $argum[1] ? $argum[1] : null; ?></td>
	    <td><?php echo $argum[2] ? $argum[2] : null; ?></td>
	    <td><?php echo $argum[3] ? $argum[3] : null; ?></td>
	    <td><?php echo $argum[4] ? $argum[4] : null; ?></td>
	    <td><?php echo $argum[5] ? $argum[5] : null; ?></td>
	  </tr>
	<?php endforeach; ?>
	</table>

	<form method="post" action="<?php echo htmlspecialchars($_SERVER["PHP_SELF"]);?>">
	   <br>
	   Prefix without mask: <input type='text' name='pref' id="pref" value='<?php echo $process_form['pref']; ?>'>
	   <span class="error">* <?php echo $prefix_Err;?></span>
	
	   <input type="radio" name="action" <?php if (isset($action) && $action=="add") echo "checked";?>  value="add">Add
	   <input type="radio" name="action" <?php if (isset($action) && $action=="del") echo "checked";?>  value="del">Delete
	   <span class="error">* <?php echo $actionErr;?></span>
	   <ba><br>
	   <br><br>
	   <input type="submit" name="submit" value="Submit"> 

	</form>
	<?php
        $parse_opts = array( 
                        "pref" 		=> array( "required"   => 1, 
                                           "match"      => "/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\z/",
                                           "validate"   => NULL),
			"action" 	=> array(  "required"   => 1, 
                                           	   "match"      => array("add", "del"),
                                           	   "validate"   => NULL)

        );
	
        list ($process_form, $has_errors) = ParseForm($parse_opts);

	if ( $has_errors or empty($_POST["action"]) or empty($_POST["pref"]) ) {
     	      echo "Prefix action and/or valid prefix is required"; 
	} else {
     	        $action = test_input($_POST["action"]);
     	        $prefix = test_input($_POST["pref"]);
		//var_dump($process_form); 
		$opts= array();
		$opts['prefix'] = $prefix;
		$opts['action'] = $action;
		$out= nfsend_query($command, $opts);
		//var_dump($out);
   	}
	//var_dump($parse_opts);
	//var_dump($iplist);
	//var_dump($_POST);
	//var_dump($parse_opts);
	//echo "<br></br>";
	//var_dump($process_form); 
	//echo "<br></br>";
	//var_dump($action);
	//var_dump($process_form["pref"]);
	var_dump($has_errors);
} // End of blackHole_Run
?>
