package require Tk

 # drawgraph.tcl --
 #    Script to draw graphs (represented as edgelist) in a canvas
 #

 # DrawGraph --
 #    Namespace for the commands
 #
 namespace eval ::DrawGraph:: {
    variable draw_vertex  "DrawVertex"
    variable draw_edge    "DrawEdge"
    variable curved       0
    variable directed     0
 }

 # DrawVertex --
 #    Default vertex drawing routine
 # Arguments:
 #    canvas    Canvas to draw on
 #    xv        X coordinate
 #    yv        Y coordinate
 #    name      Name of the vertex
 
 # Output:
 #    Filled circle drawn at vertex
 #
 proc ::DrawGraph::DrawVertex { canvas xv yv name } {
    $canvas create oval [expr {$xv-30}] [expr {$yv-30}] \
                        [expr {$xv+30}] [expr {$yv+30}] 
		
  $canvas create text   $xv $yv -text $name
 }

# DrawEdge --
 #    Default edge drawing routine
 # Arguments:
 #    canvas    Canvas to draw on
 #    xb        X coordinate begin
 #    yb        Y coordinate begin
 #    xe        X coordinate end
 #    ye        Y coordinate end
 #    curved    Draw a curved edge or not
 #    directed  Draw an arrow head or not
 #    attrib    Attribute of the vertex

 # Output:
 #    Line from the beginning to the end
 #
 proc ::DrawGraph::DrawEdge { canvas xb yb xe ye curved directed attrib } {
    if { $directed } {
       set arrowtype last
    } else {
       set arrowtype none
    }

    set dx [expr {$xe-$xb}]
    set dy [expr {$ye-$yb}]
    if { ! $curved } {
       set xc [expr {$xb+0.5*$dx}]
       set yc [expr {$yb+0.5*$dy}]
    } else {
       set xc [expr {$xb+0.5*$dx-0.1*$dy}]
       set yc [expr {$yb+0.5*$dy+0.1*$dx}]
    }
    $canvas create line $xb $yb $xc $yc $xe $ye -fill black \
       -arrow $arrowtype -smooth $curved
 }
 
set message1 "Copyright 2010\nIllinois Institute of Technology - ECE VLSI Design and Automation Lab.\nNote: Do not distribute this source code to anyone outside of ECE588 course.\n\n\nThis is a sample application to demonstrate a VLSI CAD tool.\n This tool is designed explicitly for ECE588 course work.\n Click on the browse button below to start."
set  fname ""
set mainModule ""
set counter 1
set moduleName ""
set globalModules() ""
set globalModuleNames() ""
set i 1
set index 1
set moduleString ""
set comma ","
set modules ""
set modulesSize 0
set sortedModules ""
set xaxes() ""
set yaxes() ""

# This function is used to start the application. Clicking a button in this function will initiate
# a file browser with some instructions

proc push_button {} {
        tk::toplevel .t1
        wm geometry .t1 750x480-5+40
	wm title .t1 "Select Input File"
        global message1
  
        grid [ttk::frame .t1.frm -padding "140 120 140 120"] 
        grid [ttk::label .t1.frm.lblmesaage1 -text $message1] 
	grid [ttk::button .t1.frm.btnBrowser -width 15 -text "Browse" -command "select_file"] 


	
	
}

# This function is used to select a file and extract the main module name which is same as the file name
# Here the file name will be a full path name. We have to extract only the file name and remove the path name.

proc select_file {} {

  global fname
  global mainModule
  
  set fname "[tk_getOpenFile]"
  set lst [ split $fname "/" ]
  set fname [lrange $lst end end]
  set fname [string trim $fname]
  set answer [tk_messageBox -type "yesno" -message "You have selected $fname \n Click Yes to continue Or No to select another file"]
  
  switch -- $answer {
   yes {
	   destroy .t1
           set result [regexp {(.*)\.(.*)} $fname match sub1 sub2]
           if { $result == 1 } {
            set mainModule [string trim $sub1]
           }
           set xyz [main]	
       }

    no {puts "No"}
 }
}

# This is a very important function for discovering the gatelevel-netlist topology
# This is a recursive function and module names are stored as a single string: moduleString
# Try printing the moduleString and you will see the modules being added at each call

proc putButtons { module }   {
         global globalModules
         global globalModuleNames
         global counter
         global index
         global mainModule
         global mainModuleIndex
         global moduleString
         global comma
         global modulesSize
         
      if {$module == "XOR2X1" || $module == "AOI22X1" || $module == "INVX1"} {
            return
         }
         
        for { set k 1 } { $k < $counter } { incr k } {
        if { $globalModuleNames($k,1) == $module } {
                append moduleString $module$comma                 
                set index $k
                set modulesSize [expr $modulesSize+1]
          }
        }
         
        set parent $module
        
        for { set h 1 } { $h < $globalModuleNames($index,2) } { incr h } {
                        
                       if { [catch {set module $globalModules($parent,$h)} errmsg] } {
                              return
                           }
                        # Recursion takes places here where the child module is drawn
                        set a [putButtons $module]
             }
     }
   
   # This is an important function which draws the edges between modules/gates.
   # This is also a recursive function. It draws the edges between the modules recursively
   
   proc drawModuleEdges { module } {
         global globalModules
         global globalModuleNames
         global counter
         global index
         global mainModule
         global mainModuleIndex
         global moduleString
         global comma
         global modulesSize
         global xaxes
         global yaxes
         
      if {$module == "XOR2X1" || $module == "AOI22X1" || $module == "INVX1"} {
            return
         }

        
        for { set k 1 } { $k < $counter } { incr k } {
        if { $globalModuleNames($k,1) == $module } {
                set index $k
                set modulesSize [expr $modulesSize+1]
          }
        }
        
        
        set parent $module
        
        for { set h 1 } { $h < $globalModuleNames($index,2) } { incr h } {
                        
                       if { [catch {set module $globalModules($parent,$h)} errmsg] } {
                              return
                           }
                           
                        if {$module != "XOR2X1" && $module != "AOI22X1" && $module != "INVX1"} {
                          ::DrawGraph::DrawEdge .t2.c1 [expr $xaxes($parent)+25] $yaxes($parent) [expr $xaxes($module)-35] [expr $yaxes($module)-5] 0 1 0
                        }
                        #Recursion takes place here
                        set a [drawModuleEdges $module]
             }
   }
   
   
   # This is a the main function which draws the modules on the GUI
   # Various modules discovered in the putButtons function is extracted and placed on the GUI using this function
   # The geometry calculation is made in this function for each module and x,y axes are stored for later use to
   # draw the edges
   
  proc main {} {
    global  fname
    global result
    global mainModule
    global counter
    global moduleName
    global globalModules
    global globalModuleNames
    global i
    global index
    global moduleString
    global comma
    global modules
    global modulesSize
    global sortedModules
   
    toplevel .t2
    set infile [open $fname r]

    while { [ gets $infile line ] >= 0 } {
     set result [regexp {module(.*)\(.*\);} $line match sub1 sub2]
     if { $result == 1 } {
        set i 1
        set moduleName [string trim $sub1]
        set globalModuleNames($counter,1) $moduleName
     }

     set result [regexp {(.*)\s+(.*)\s+\(.*\);} $line match sub1 sub2 sub3]
     if { $result == 1 && $sub1 != "module" } {
        set globalModules($moduleName,$i) [string trim $sub1]
        incr i
     }
     
       set result [regexp {(endmodule)} $line match sub1]
       if { $result == 1 } {
        set globalModuleNames($counter,2) $i
        incr counter
       }
     }
    
    # Extract all the module names using recursive function : putButtons
    
    set a [putButtons $mainModule]
    set moduleString [string trimright $moduleString ","]
    set modules [split $moduleString ,]
    
    set factor 2
    set result [regexp {(PRJ)(\d+)(.*)} $mainModule match sub1 sub2 sub3]
    set start [expr $sub2/$factor]
    
    set canvasHeight 600
    set canvasWidth 800
    set scaleFactor 2
    set xaxis 100
    set yaxis [expr $canvasHeight/2]
    global xaxes
    global yaxes
    
    canvas .t2.c1 -background gray -relief sunken -width $canvasWidth -height $canvasHeight
    pack .t2.c1
    
    .t2.c1 create text [expr $xaxis-20] [expr $yaxis-250] -text "File: $fname"
    .t2.c1 create text $xaxis $yaxis -text $mainModule -tag $mainModule
    .t2.c1 bind $mainModule <1> "display $mainModule"
    
    # X-axis and Y-axis are recorded so that we can draw the edges later
    
    set xaxes($mainModule) $xaxis
    set yaxes($mainModule) $yaxis
 
    # This part places different levels of modules at equal spacing from left to right
    
    while { $start != 1 } {
       set xaxis [expr $xaxis+150]
       set yincr [expr ($canvasHeight/($scaleFactor+1))]
       set yaxis $yincr
       
       foreach item $modules {
         set result [regexp {(PRJ)(\d+)(.*)} $item match sub11 sub22 sub33]
         if { $result == 1} {
          if { $sub22 == $start } {
            .t2.c1 create text $xaxis $yaxis -text $item -tag $item
            .t2.c1 bind $item <1> "display $item"
            set xaxes($item) $xaxis
            set yaxes($item) $yaxis
            set yaxis [expr $yaxis+$yincr]
          }
         }
       }
       set start [expr $start/2]
       set scaleFactor [expr $scaleFactor*2]
     }
    
      set yincr [expr ($canvasHeight/($scaleFactor+1))]
      set yaxis $yincr
      
      foreach item $modules {
         set result [regexp {(Project.*)} $item match sub11]
         if { $result == 1} {
            .t2.c1 create text $xaxis $yaxis -text $item -tag $item
            .t2.c1 bind $item <1> "display $item"
            set xaxes($item) $xaxis
            set yaxes($item) $yaxis
            set yaxis [expr $yaxis+$yincr]
         }
      }
    
      set xyz [drawModuleEdges $mainModule]
    }

      #set xyz [main]
      
      # The program starts executing here. This is the starting point of the program.
      # It draws the start button and binds the button with push_button procedure
      
      grid [ttk::button .but -text "Start Application" -command "push_button"]
      pack .but

   
   # This function will check if a module is a full adder or a RCA module.
   # If it is a full adder block then it calls drawModule which will draw
   # the detailed view of full adder block.
   
   proc display { param } {
       global globalModuleNames
       global globalModules
       global counter
       set index 0
      
       set result [regexp {(Project.*)} $param match sub11]
       if {$result == 1 } {
        set b [drawModule $param]
       }
       
       set result [regexp {(PRJ.*)} $param match sub11]
       if { $result == 1 } {
		 set b [drawModule $param]
       }
       
   }
   
 
 proc MAX {inputs outputs} {
   if {$inputs > $outputs} {
      return $inputs
     } else {
       return $outputs
     }
  }
  
  # This module will draw the detailed view of the full adder block
  # This module will analyze the gates in the full adder block
  # It will analyze the interconnections between the gates and draws the gates

  
  proc drawModule { module } {
   set numOfInputs 0
   set numOfOutputs 0
   set numOfGates 0

   set canvasHeight 0
   set canvasWidth 0
   set gateCount 0

   set inputs ""
   set outputs ""

   set PRJ16 ""
   set PRJ8b ""
   set PRJ4b ""
   set Project ""
   set XOR ""
   set AOI ""
   set INV ""

   set xaxis() ""
   set yaxis() ""

   set gates() ""

   set i 0
   set j 0
   set oldgate ""
   set waitprocess [list ""]
   global fname
   
   toplevel .t1
   # Read input file line by line
   
   set infile [open $fname r]
   set tempfile [open "temp.gv" w]

  while { [ gets $infile line ] >= 0 } {
    set result [regexp {module(.*)\(.*\);} $line match sub1]
    if { $result == 1 && $module == [string trim $sub1] } {
         break
    }
  }

 while { [ gets $infile line ] >= 0 } {
    if {$line == "endmodule"} {
      puts $tempfile $line
      break
    }
    puts $tempfile $line
  }

  close $infile
  close $tempfile

  set outfile [open "temp.gv" r]

  while { [ gets $outfile line ] >= 0 } {

  # Read the module name at the beginning of the module

   set moduleName [string range $module 0 4]

   # Read the inputs and number of inputs from the next line 

    switch $moduleName {
		"PRJ4b" {
			set result [regexp {(input) (.*);} $line match sub1 sub2]
			if {$result == 1} {
				set result [regexp {\[(.*)\:(.*)\] (.*)} $sub2 match sub3 sub4 sub5]
				if {$result == 1} {
					for { set k $sub4 } { $k <= $sub3 } { incr k } {
						lappend inputs [concat $sub5\[$k\]]
					}
					set numOfInputs [llength $inputs]
				} else {
					lappend inputs [concat $sub2]
					set numOfInputs [llength $inputs]
				}
			}
		}
		"PRJ8b" {
			set result [regexp {(input) (.*);} $line match sub1 sub2]
			if {$result == 1} {
				set result [regexp {\[(.*)\:(.*)\] (.*)} $sub2 match sub3 sub4 sub5]
				if {$result == 1} {
					lappend inputs [concat $sub5\[3:0\]]
					lappend inputs [concat $sub5\[7:4\]]
					set numOfInputs [llength $inputs]
				} else {
					lappend inputs [concat $sub2]
					set numOfInputs [llength $inputs]
				}
			}
		}
		"PRJ16" {
			set result [regexp {(input) (.*);} $line match sub1 sub2]
			if {$result == 1} {
				set result [regexp {\[(.*)\:(.*)\] (.*)} $sub2 match sub3 sub4 sub5]
				if {$result == 1} {
					lappend inputs [concat $sub5\[7:0\]]
					lappend inputs [concat $sub5\[15:8\]]
					set numOfInputs [llength $inputs]
				} else {
					lappend inputs [concat $sub2]
					set numOfInputs [llength $inputs]
				}
			}
		}
		default {
			set result [regexp {(input) (.*);} $line match sub1 sub2]
			if {$result == 1} {
				set inputs [split $sub2 ,]
				set numOfInputs [llength $inputs]
			}
		 }
	 }

   # Read the outputs and number of outpus from the next line
	   switch $moduleName {
		"PRJ4b" {
			set result [regexp {(output) (.*);} $line match sub1 sub2]
			if {$result == 1} {
				set result [regexp {\[(.*)\:(.*)\] (.*)} $sub2 match sub3 sub4 sub5]
				if {$result == 1} {
					for { set k $sub4 } { $k <= $sub3 } { incr k } {
						lappend outputs [concat $sub5\[$k\]]
					}
					set numOfOutputs [llength $outputs]
				} else {
					lappend outputs [concat $sub2]
					set numOfOutputs [llength $outputs]
				}
			}
		}
		"PRJ8b" {
			set result [regexp {(output) (.*);} $line match sub1 sub2]
			if {$result == 1} {
				set result [regexp {\[(.*)\:(.*)\] (.*)} $sub2 match sub3 sub4 sub5]
				if {$result == 1} {
					lappend outputs [concat $sub5\[3:0\]]
					lappend outputs [concat $sub5\[7:4\]]
					set numOfOutputs [llength $outputs]
				} else {
					lappend outputs [concat $sub2]
					set numOfOutputs [llength $outputs]
				}
			}
		}
		"PRJ16" {
			set result [regexp {(output) (.*);} $line match sub1 sub2]
			if {$result == 1} {
				set result [regexp {\[(.*)\:(.*)\] (.*)} $sub2 match sub3 sub4 sub5]
				if {$result == 1} {
					lappend outputs [concat $sub5\[7:0\]]
					lappend outputs [concat $sub5\[15:8\]]
					set numOfOutputs [llength $outputs]
				} else {
					lappend outputs [concat $sub2]
					set numOfOutputs [llength $outputs]
				}
			}
		}
		default {
			set result [regexp {(output) (.*);} $line match sub1 sub2]
			if {$result == 1} {
				set outputs [split $sub2 ,]
				set numOfOutputs [llength $outputs]
			}
		 }
	 }

   # Read gate information from the rest of the lines until enmodule is recognized

   # 2-Input XOR is recognized here

    set result [regexp {(XOR).*(\d\d).*\((.*)\).*\((.*)\).*\((.*)\).*\)} $line match sub1 sub2 sub3 sub4 sub5]
    if {$result == 1} {
     incr gateCount
     
     set i [expr $i+1]
     set j 1
     set gates($i,$j) $sub1
     incr j
     set gates($i,$j) $sub2
     incr j
     set gates($i,$j) $sub3
     incr j
     set gates($i,$j) $sub4
     incr j
     set gates($i,$j) $sub5
   }

   # Inverter is recognized here

   set result [regexp {(INV).*(\d\d).*\((.*)\).*\((.*)\).*\)} $line match sub1 sub2 sub3 sub4] 
   if {$result == 1} {
     incr gateCount

     set i [expr $i+1]
     set j 1
     set gates($i,$j) $sub1
     incr j
     set gates($i,$j) $sub2
     incr j
     set gates($i,$j) $sub3
     incr j
     set gates($i,$j) $sub4
   }

   # AOI is recognized here
     
    set result [regexp {(AOI).*(\d\d).*\((.*)\).*\((.*)\).*\((.*)\).*\((.*)\).*\((.*)\).*\)} $line match sub1 sub2 sub3 sub4 sub5 sub6 sub7] 
    if {$result == 1} {
     incr gateCount

     set i [expr $i+1]
     set j 1
     set gates($i,$j) $sub1
     incr j
     set gates($i,$j) $sub2
     incr j
     set gates($i,$j) $sub3
     incr j
     set gates($i,$j) $sub4
     incr j
     set gates($i,$j) $sub5
     incr j
     set gates($i,$j) $sub6
     incr j
     set gates($i,$j) $sub7
   }
   
   # FullAdder is recognized here
   
	set result [regexp {(Project).*(\d\d).*\((.*)\).*\((.*)\).*\((.*)\).*\((.*)\).*\((.*)\).*\)} $line match sub1 sub2 sub3 sub4 sub5 sub6 sub7] 
    if {$result == 1} {
     incr gateCount

     set i [expr $i+1]
     set j 1
     set gates($i,$j) $sub1
     incr j
     set gates($i,$j) $sub2
     incr j
     set gates($i,$j) $sub3
     incr j
     set gates($i,$j) $sub4
     incr j
     set gates($i,$j) $sub5
     incr j
     set gates($i,$j) $sub6
     incr j
     set gates($i,$j) $sub7
   }
   
	#RCA4b is recognized here
   
	set result [regexp {(PRJ4b).*(\d\d).*\((.*)\).*\((.*)\).*\((.*)\).*\((.*)\).*\((.*)\).*\)} $line match sub1 sub2 sub3 sub4 sub5 sub6 sub7] 
    if {$result == 1} {
     incr gateCount

     set i [expr $i+1]
     set j 1
     set gates($i,$j) $sub1
     incr j
     set gates($i,$j) $sub2
     incr j
     set gates($i,$j) $sub3
     incr j
     set gates($i,$j) $sub4
     incr j
     set gates($i,$j) $sub5
     incr j
     set gates($i,$j) $sub6
     incr j
     set gates($i,$j) $sub7
   } else {
		set result [regexp {(PRJ4b).*\_(\d).*\((.*)\).*\((.*)\).*\((.*)\).*\((.*)\).*\((.*)\).*\)} $line match sub1 sub2 sub3 sub4 sub5 sub6 sub7] 
	    if {$result == 1} {
	     incr gateCount

	     set i [expr $i+1]
	     set j 1
	     set gates($i,$j) $sub1
	     incr j
	     set gates($i,$j) $sub2
	     incr j
	     set gates($i,$j) $sub3
	     incr j
	     set gates($i,$j) $sub4
	     incr j
	     set gates($i,$j) $sub5
	     incr j
	     set gates($i,$j) $sub6
	     incr j
	     set gates($i,$j) $sub7
		}
	}
   
   # RCA8b is recognized here
   
	set result [regexp {(PRJ8b).*(\d\d).*\((.*)\).*\((.*)\).*\((.*)\).*\((.*)\).*\((.*)\).*\)} $line match sub1 sub2 sub3 sub4 sub5 sub6 sub7] 
    if {$result == 1} {
     incr gateCount

     set i [expr $i+1]
     set j 1
     set gates($i,$j) $sub1
     incr j
     set gates($i,$j) $sub2
     incr j
     set gates($i,$j) $sub3
     incr j
     set gates($i,$j) $sub4
     incr j
     set gates($i,$j) $sub5
     incr j
     set gates($i,$j) $sub6
     incr j
     set gates($i,$j) $sub7
   } else {
		set result [regexp {(PRJ8b).*\_(\d).*\((.*)\).*\((.*)\).*\((.*)\).*\((.*)\).*\((.*)\).*\)} $line match sub1 sub2 sub3 sub4 sub5 sub6 sub7] 
	    if {$result == 1} {
	     incr gateCount

	     set i [expr $i+1]
	     set j 1
	     set gates($i,$j) $sub1
	     incr j
	     set gates($i,$j) $sub2
	     incr j
	     set gates($i,$j) $sub3
	     incr j
	     set gates($i,$j) $sub4
	     incr j
	     set gates($i,$j) $sub5
	     incr j
	     set gates($i,$j) $sub6
	     incr j
	     set gates($i,$j) $sub7
		}
	}
   
   set result [regexp {(endmodule)} $line match sub1] 
   if {$result == 1} {
      set canvasWidth [ expr $gateCount*200 ]
      set max [ MAX $numOfInputs $numOfOutputs ]
      set canvasHeight [ expr $max*80 ]

      canvas .t1.c2 -bg gray -width $canvasWidth -height $canvasHeight
      grid .t1.c2

      set yincr 0
      set total [expr $numOfInputs+$numOfOutputs+$gateCount]

      # Inputs gates are drawn here. The nodes placement is calculated and placed at equal distances
      
      foreach item $inputs {
	   set item [string trim $item]
	   ::DrawGraph::DrawVertex .t1.c2 [expr ($canvasWidth/$total)+20] [expr (($canvasHeight-50)/$numOfInputs)+$yincr] $item
	   set xaxis($item) [expr ($canvasWidth/$total)+20]
	   set yaxis($item) [expr (($canvasHeight-50)/$numOfInputs)+$yincr]
	   set yincr [expr $yincr+(($canvasHeight-50)/$numOfInputs)]
	  }

	  set yincr 0
	  set total [expr $numOfInputs+$numOfOutputs+$gateCount]

	  # Outputs gates are drawn here. The nodes placement is calculated and placed at equal distances
	  
	  foreach item $outputs {
	   set item [string trim $item]
	   ::DrawGraph::DrawVertex .t1.c2 [expr $canvasWidth-($canvasWidth/$total)-20] [expr (($canvasHeight-50)/$numOfOutputs)+$yincr] $item
	   set xaxis($item) [expr $canvasWidth-($canvasWidth/$total)-20]
	   set yaxis($item) [expr (($canvasHeight-50)/$numOfOutputs)+$yincr]
	   set yincr [expr $yincr+(($canvasHeight-50)/$numOfOutputs)]
	  }		  
	 } 
}

# Intermediate gates are drawn from here. Depending upon the number of gate the netlist is analyzed.
# This part determines which gates should be placed in front of input gates, which nodes are placed
# behind the output gates. Which wires connect between the nodes and all other details.

	for { set k 1 } { $k <= $i } { incr k } {	
	set xaxis($gates($k,1)$gates($k,2)) ""	
}

for { set k 1 } { $k <= $i } { incr k } {
   set gate $gates($k,1)
   if {$gate == "XOR"} {
       set result [regexp {(out.*)} $gates($k,5) match sub1]
       if {$result == 1} {
         set total [expr $numOfInputs+$numOfOutputs+$gateCount]
         set xaxis($gates($k,1)$gates($k,2)) [expr $xaxis($gates($k,5))-2*($canvasWidth/$total)]
         set yaxis($gates($k,1)$gates($k,2)) [expr $yaxis($gates($k,5))]
         ::DrawGraph::DrawVertex .t1.c2 $xaxis($gates($k,1)$gates($k,2)) $yaxis($gates($k,1)$gates($k,2)) $gates($k,1)$gates($k,2)         
       }
    }

   if {$gate == "INV"} {
       set result [regexp {(out.*)} $gates($k,4) match sub1]
       if {$result == 1} {
	 set total [expr $numOfInputs+$numOfOutputs+$gateCount]
	 set xaxis($gates($k,1)$gates($k,2)) [expr $xaxis($gates($k,4))-2*($canvasWidth/$total)]
         set yaxis($gates($k,1)$gates($k,2)) [expr $yaxis($gates($k,4))]
         ::DrawGraph::DrawVertex .t1.c2 $xaxis($gates($k,1)$gates($k,2)) $yaxis($gates($k,1)$gates($k,2)) $gates($k,1)$gates($k,2)
       }
    }

     if {$gate == "AOI"} {
       set result [regexp {(out.*)} $gates($k,7) match sub1]
       if {$result == 1} {
	 set total [expr $numOfInputs+$numOfOutputs+$gateCount]
         set xaxis($gates($k,1)$gates($k,2)) [expr $xaxis($gates($k,7))-2*($canvasWidth/$total)]
         set yaxis($gates($k,1)$gates($k,2)) [expr $yaxis($gates($k,7))]
         ::DrawGraph::DrawVertex .t1.c2 $xaxis($gates($k,1)$gates($k,2)) $yaxis($gates($k,1)$gates($k,2)) $gates($k,1)$gates($k,2)
         }
    }
	
	if {$gate == "Project"} {
       set result [regexp {(out.*)} $gates($k,6) match sub1]
       if {$result == 1} {
	 set total [expr $numOfInputs+$numOfOutputs+$gateCount]
         set xaxis($gates($k,1)$gates($k,2)) [expr $xaxis($gates($k,6))-2*($canvasWidth/$total)-100]
         set yaxis($gates($k,1)$gates($k,2)) [expr $yaxis($gates($k,6))]
         ::DrawGraph::DrawVertex .t1.c2 $xaxis($gates($k,1)$gates($k,2)) $yaxis($gates($k,1)$gates($k,2)) $gates($k,1)$gates($k,2)
         }
    }
	
	if {$gate == "PRJ4b"} {
       set result [regexp {(out.*)} $gates($k,6) match sub1]
       if {$result == 1} {
	 set total [expr $numOfInputs+$numOfOutputs+$gateCount]
         set xaxis($gates($k,1)$gates($k,2)) [expr $xaxis($gates($k,6))-2*($canvasWidth/$total)-50]
         set yaxis($gates($k,1)$gates($k,2)) [expr $yaxis($gates($k,6))]
         ::DrawGraph::DrawVertex .t1.c2 $xaxis($gates($k,1)$gates($k,2)) $yaxis($gates($k,1)$gates($k,2)) $gates($k,1)$gates($k,2)
         }
    }
	
	if {$gate == "PRJ8b"} {
       set result [regexp {(out.*)} $gates($k,6) match sub1]
       if {$result == 1} {
	 set total [expr $numOfInputs+$numOfOutputs+$gateCount]
         set xaxis($gates($k,1)$gates($k,2)) [expr $xaxis($gates($k,6))-2*($canvasWidth/$total)-50]
         set yaxis($gates($k,1)$gates($k,2)) [expr $yaxis($gates($k,6))]
         ::DrawGraph::DrawVertex .t1.c2 $xaxis($gates($k,1)$gates($k,2)) $yaxis($gates($k,1)$gates($k,2)) $gates($k,1)$gates($k,2)
         }
    }
 }

for { set k 1 } { $k <= $i } { incr k } {
   set gate $gates($k,1)
   set actualgate $gates($k,1)$gates($k,2)

   if { $gate == "XOR" } {
       # Matches if a gate is XOR and it's output is a wire
       
       set result [regexp {(n.*)} $gates($k,5) match sub1]
   
       if { $result == 1 } {
	
	    for { set x 1 } { $x <= $i } { incr x } {

	      if { $gates($x,1) == "XOR" } {
              
		if { $gates($x,3) == $sub1 } {
		  set oldgate $gates($x,1)$gates($x,2)
		  break
		 }
               
	        if { $gates($x,4) == $sub1 } {
		   set oldgate $gates($x,1)$gates($x,2)
		   break
		 }
	       }

            if { $gates($x,1) == "AOI" } {

	      if { $gates($x,3) == $sub1 } {
	         set oldgate $gates($x,1)$gates($x,2)
		 break
		}
               
	        if { $gates($x,4) == $sub1 } {
		   set oldgate $gates($x,1)$gates($x,2)
		   break
		 }

		 if { $gates($x,5) == $sub1 } {
		   set oldgate $gates($x,1)$gates($x,2)
		   break
		 }

		 if { $gates($x,6) == $sub1 } {
		   set oldgate $gates($x,1)$gates($x,2)
		   break
		 }
	     }

	     if { $gates($x,1) == "INV" } {
               if { $gates($x,3) == $sub1 } {
		  set oldgate $gates($x,1)$gates($x,2)
		  break
		 }
	      }
	  }
	}
      }


       if { $gate == "AOI" } {
       # Matches if a gate is AOI and it's output is a wire
       set result [regexp {(n.*)} $gates($k,7) match sub1]
       if { $result == 1 } {
	
	    for { set x 1 } { $x <= $i } { incr x } {

	      if { $gates($x,1) == "XOR" } {
              
		if { $gates($x,3) == $sub1 } {
		  set oldgate $gates($x,1)$gates($x,2)
		  break
		 }
               
	        if { $gates($x,4) == $sub1 } {
		   set oldgate $gates($x,1)$gates($x,2)
		   break
		 }
	       }

            if { $gates($x,1) == "AOI" } {

	      if { $gates($x,3) == $sub1 } {
	         set oldgate $gates($x,1)$gates($x,2)
		 break
		}
               
	        if { $gates($x,4) == $sub1 } {
		   set oldgate $gates($x,1)$gates($x,2)
		   break
		 }

		 if { $gates($x,5) == $sub1 } {
		   set oldgate $gates($x,1)$gates($x,2)
		   break
		 }

		 if { $gates($x,6) == $sub1 } {
		   set oldgate $gates($x,1)$gates($x,2)
		   break
		 }
	     }

	     if { $gates($x,1) == "INV" } {
               if { $gates($x,3) == $sub1 } {
		  set oldgate $gates($x,1)$gates($x,2)
		  break
		 }
	      }
	  }
	}
      }

      if { $gate == "INV" } {
       # Matches if a gate is INV and it's output is a wire
       set result [regexp {(n.*)} $gates($k,4) match sub1]
   
       if { $result == 1 } {
	
	    for { set x 1 } { $x <= $i } { incr x } {

	      if { $gates($x,1) == "XOR" } {
              
		if { $gates($x,3) == $sub1 } {
		  set oldgate $gates($x,1)$gates($x,2)
		  break
		 }
               
	        if { $gates($x,4) == $sub1 } {
		   set oldgate $gates($x,1)$gates($x,2)
		   break
		 }
	       }

            if { $gates($x,1) == "AOI" } {

	      if { $gates($x,3) == $sub1 } {
	         set oldgate $gates($x,1)$gates($x,2)
		 break
		}
               
	        if { $gates($x,4) == $sub1 } {
		   set oldgate $gates($x,1)$gates($x,2)
		   break
		 }

		 if { $gates($x,5) == $sub1 } {
		   set oldgate $gates($x,1)$gates($x,2)
		   break
		 }

		 if { $gates($x,6) == $sub1 } {
		   set oldgate $gates($x,1)$gates($x,2)
		   break
		 }
	     }

	     if { $gates($x,1) == "INV" } {
               if { $gates($x,3) == $sub1 } {
		  set oldgate $gates($x,1)$gates($x,2)
		  break
		 }
	      }
	   }
	}
      }

 if {$oldgate != ""} {	
       # After determining the input and output gate from the above loop edges are drawn.	
       set total [expr $numOfInputs+$numOfOutputs+$gateCount]	
       if {$xaxis($oldgate) != ""} {	
    	   set xaxis($actualgate) [expr $xaxis($oldgate)-2*($canvasWidth/$total)]	
           set yaxis($actualgate) [expr $yaxis($oldgate)]	
      	   ::DrawGraph::DrawVertex .t1.c2 $xaxis($actualgate) $yaxis($actualgate) $actualgate	
	   set oldgate ""	
       } else {	
	   set templist [list $actualgate $oldgate]	
    	   lappend waitprocess $templist	
	   set oldgate ""	
       }	
      } 	
  }	
while {[llength $waitprocess] > 1} {	
	set k 0	
	set index 0	
	set tempoldgate ""	
	set tempgate ""	
	foreach item $waitprocess {	
		set tempgate [lindex $item 0]	
		set tempoldgate [lindex $item 1]	
		if {$xaxis($tempoldgate) != ""} {	
			set total [expr $numOfInputs+$numOfOutputs+$gateCount]	
			set xaxis($tempgate) [expr $xaxis($tempoldgate)-2*($canvasWidth/$total)]	
			set yaxis($tempgate) [expr $yaxis($tempoldgate)]	
			::DrawGraph::DrawVertex .t1.c2 $xaxis($tempgate) $yaxis($tempgate) $tempgate	
				
			set index $k	
		}	
		incr k	 	
        }	
	if {$index != 0} {	
		set waitprocess [lreplace $waitprocess $index $index]	
	} 	
}


# Edges are drawn from here 

set ingate ""
set outgate ""

for { set k 1 } { $k <= $i } { incr k } {

  if { $gates($k,1) == "XOR" } {
    
    for { set l 3 } { $l <= 5 } { incr l } {
    
      if { $l == 5 } {
            set result [regexp {(n.*)} $gates($k,$l) match sub1]
            if { $result == 1 } {
	      break
	     }
       }
       
      # Matches with the input gate.
      set result [regexp {(in.*)} $gates($k,$l) match sub1]

      if {$result == 1} {
           set ingate $gates($k,$l)
           set outgate $gates($k,1)$gates($k,2)
           ::DrawGraph::DrawEdge .t1.c2 [expr $xaxis($ingate)+30] $yaxis($ingate) [expr $xaxis($outgate)-30] $yaxis($outgate) 0 1 0
	 }

      set result [regexp {(n.*)} $gates($k,$l) match sub1]

      if { $result == 1 } {
            set outgate $gates($k,1)$gates($k,2)

            for { set j 1 } { $j <= $i } { incr j } {

	       if { $gates($j,1) == "XOR" } {

	          if { $gates($j,5) == $sub1 } {
		    set ingate $gates($j,1)$gates($j,2)
                    break
		   }
	       }

		if { $gates($j,1) == "INV" } {

	          if { $gates($j,4) == $sub1 } {
		    set ingate $gates($j,1)$gates($j,2)
                    break
		   }
	       }

		
		if { $gates($j,1) == "AOI" } {

	          if { $gates($j,7) == $sub1 } {
		    set ingate $gates($j,1)$gates($j,2)
                    break
		   }
  	        }

	     }
             ::DrawGraph::DrawEdge .t1.c2 [expr $xaxis($ingate)+30] $yaxis($ingate) [expr $xaxis($outgate)-30] $yaxis($outgate) 0 1 0
          }
          
            set result [regexp {(out.*)} $gates($k,$l) match sub1]
            if { $result == 1 } {
             set outgate $gates($k,$l)
             set ingate $gates($k,1)$gates($k,2)
             ::DrawGraph::DrawEdge .t1.c2 [expr $xaxis($ingate)+30] $yaxis($ingate) [expr $xaxis($outgate)-30] $yaxis($outgate) 0 1 0
            }
	}
      }



    if { $gates($k,1) == "INV" } {

    for { set l 3 } { $l <= 4 } { incr l } {

      if { $l == 4 } {
         set result [regexp {(n.*)} $gates($k,$l) match sub1]
         if { $result == 1 } {
	     break
	  }
       }

    
      set result [regexp {(in.*)} $gates($k,$l) match sub1]

      if {$result == 1} {
           set ingate $gates($k,$l)
           set outgate $gates($k,1)$gates($k,2)
           ::DrawGraph::DrawEdge .t1.c2 [expr $xaxis($ingate)+30] $yaxis($ingate) [expr $xaxis($outgate)-30] $yaxis($outgate) 0 1 0
	 }

      set result [regexp {(n.*)} $gates($k,$l) match sub1]
      if { $result == 1 } {
            set outgate $gates($k,1)$gates($k,2)
	    for { set j 1 } { $j <= $i } { incr j } {

	       if { $gates($j,1) == "XOR" } {
	          if { $gates($j,5) == $sub1 } {
		    set ingate $gates($j,1)$gates($j,2)
                    break
		   }
	       }

		if { $gates($j,1) == "INV" } {
	          if { $gates($j,4) == $sub1 } {
		    set ingate $gates($j,1)$gates($j,2)
                    break
		   }
	       }

		
		if { $gates($j,1) == "AOI" } {
	          if { $gates($j,7) == $sub1 } {
		    set ingate $gates($j,1)$gates($j,2)
                    break
		   }
  	        }

	     }
             ::DrawGraph::DrawEdge .t1.c2 [expr $xaxis($ingate)+30] $yaxis($ingate) [expr $xaxis($outgate)-30] $yaxis($outgate) 0 1 0
          }
          
            set result [regexp {(out.*)} $gates($k,$l) match sub1]
            if { $result == 1 } {
             set outgate $gates($k,$l)
             set ingate $gates($k,1)$gates($k,2)
             ::DrawGraph::DrawEdge .t1.c2 [expr $xaxis($ingate)+30] $yaxis($ingate) [expr $xaxis($outgate)-30] $yaxis($outgate) 0 1 0
            }
	}
      }
  

   if { $gates($k,1) == "AOI" } {

    for { set l 3 } { $l <= 7 } { incr l } {
      

       if { $l == 7 } {
         set result [regexp {(n.*)} $gates($k,$l) match sub1]
         if { $result == 1 } {
	     break
	  }
       }

      set result [regexp {(in.*)} $gates($k,$l) match sub1]

      if {$result == 1} {
           set ingate $gates($k,$l)
           set outgate $gates($k,1)$gates($k,2)
           ::DrawGraph::DrawEdge .t1.c2 [expr $xaxis($ingate)+30] $yaxis($ingate) [expr $xaxis($outgate)-30] $yaxis($outgate) 0 1 0
	 }

      set result [regexp {(n.*)} $gates($k,$l) match sub1]
      if { $result == 1 } {
            set outgate $gates($k,1)$gates($k,2)
	    for { set j 1 } { $j <= $i } { incr j } {

	       if { $gates($j,1) == "XOR" } {
	          if { $gates($j,5) == $sub1 } {
		    set ingate $gates($j,1)$gates($j,2)
                    break
		   }
	       }

		if { $gates($j,1) == "INV" } {
	          if { $gates($j,4) == $sub1 } {
		    set ingate $gates($j,1)$gates($j,2)
                    break
		   }
	       }

		
		if { $gates($j,1) == "AOI" } {
	          if { $gates($j,7) == $sub1 } {
		    set ingate $gates($j,1)$gates($j,2)
                    break
		   }
  	        }

	     }
             ::DrawGraph::DrawEdge .t1.c2 [expr $xaxis($ingate)+30] $yaxis($ingate) [expr $xaxis($outgate)-30] $yaxis($outgate) 0 1 0
          }
          
            set result [regexp {(out.*)} $gates($k,$l) match sub1]
            if { $result == 1 } {
             set outgate $gates($k,$l)
             set ingate $gates($k,1)$gates($k,2)
             ::DrawGraph::DrawEdge .t1.c2 [expr $xaxis($ingate)+30] $yaxis($ingate) [expr $xaxis($outgate)-30] $yaxis($outgate) 0 1 0
            }
	}
      }	  

 if { $gates($k,1) == "Project" } {
    
    for { set l 3 } { $l <= 7 } { incr l } {
    
      if { $l == 7 } {
            set result [regexp {(co.*)} $gates($k,$l) match sub1]
            if { $result == 1 } {
	      break
	     }
       }
       
      # Matches with the input gate.
      set result [regexp {(in.*)} $gates($k,$l) match sub1]

      if {$result == 1} {
           set ingate $gates($k,$l)
           set outgate $gates($k,1)$gates($k,2)
           ::DrawGraph::DrawEdge .t1.c2 [expr $xaxis($ingate)+30] $yaxis($ingate) [expr $xaxis($outgate)-30] $yaxis($outgate) 0 1 0
	 }

      set result [regexp {(co.*)} $gates($k,$l) match sub1]

      if { $result == 1 } {
            set outgate $gates($k,1)$gates($k,2)

            for { set j 1 } { $j <= $i } { incr j } {

			if { $gates($j,1) == "Project" } {

	          if { $gates($j,7) == $sub1 } {
		    set ingate $gates($j,1)$gates($j,2)
                    break
		   }
	       }

	     }
             ::DrawGraph::DrawEdge .t1.c2 $xaxis($ingate) [expr $yaxis($ingate)+30] $xaxis($outgate) [expr $yaxis($outgate)-30] 0 1 0
          }
		  
		  
          
            set result [regexp {(out.*)} $gates($k,$l) match sub1]
            if { $result == 1 } {
             set outgate $gates($k,$l)
             set ingate $gates($k,1)$gates($k,2)
             ::DrawGraph::DrawEdge .t1.c2 [expr $xaxis($ingate)+30] $yaxis($ingate) [expr $xaxis($outgate)-30] $yaxis($outgate) 0 1 0
            }
	}
      }
	  
	   if { $gates($k,1) == "PRJ4b" } {
    
    for { set l 3 } { $l <= 7 } { incr l } {
    
      if { $l == 7 } {
            set result [regexp {(co.*)} $gates($k,$l) match sub1]
            if { $result == 1 } {
	      break
	     }
       }
       
      # Matches with the input gate.
      set result [regexp {(in.*)} $gates($k,$l) match sub1]

      if {$result == 1} {
           set ingate $gates($k,$l)
           set outgate $gates($k,1)$gates($k,2)
           ::DrawGraph::DrawEdge .t1.c2 [expr $xaxis($ingate)+30] $yaxis($ingate) [expr $xaxis($outgate)-30] $yaxis($outgate) 0 1 0
	 }

      set result [regexp {(co.*)} $gates($k,$l) match sub1]

      if { $result == 1 } {
            set outgate $gates($k,1)$gates($k,2)

            for { set j 1 } { $j <= $i } { incr j } {

			if { $gates($j,1) == "PRJ4b" } {

	          if { $gates($j,7) == $sub1 } {
		    set ingate $gates($j,1)$gates($j,2)
                    break
		   }
	       }

	     }
             ::DrawGraph::DrawEdge .t1.c2 $xaxis($ingate) [expr $yaxis($ingate)+30] $xaxis($outgate) [expr $yaxis($outgate)-30] 0 1 0
          }
		  
		  
          
            set result [regexp {(out.*)} $gates($k,$l) match sub1]
            if { $result == 1 } {
             set outgate $gates($k,$l)
             set ingate $gates($k,1)$gates($k,2)
             ::DrawGraph::DrawEdge .t1.c2 [expr $xaxis($ingate)+30] $yaxis($ingate) [expr $xaxis($outgate)-30] $yaxis($outgate) 0 1 0
            }
	}
      }
	  
	 if { $gates($k,1) == "PRJ8b" } {
    
    for { set l 3 } { $l <= 7 } { incr l } {
    
      if { $l == 7 } {
            set result [regexp {(co.*)} $gates($k,$l) match sub1]
            if { $result == 1 } {
	      break
	     }
       }
       
      # Matches with the input gate.
      set result [regexp {(in.*)} $gates($k,$l) match sub1]

      if {$result == 1} {
           set ingate $gates($k,$l)
           set outgate $gates($k,1)$gates($k,2)
           ::DrawGraph::DrawEdge .t1.c2 [expr $xaxis($ingate)+30] $yaxis($ingate) [expr $xaxis($outgate)-30] $yaxis($outgate) 0 1 0
	 }

      set result [regexp {(co.*)} $gates($k,$l) match sub1]

      if { $result == 1 } {
            set outgate $gates($k,1)$gates($k,2)

            for { set j 1 } { $j <= $i } { incr j } {

			if { $gates($j,1) == "PRJ8b" } {

	          if { $gates($j,7) == $sub1 } {
		    set ingate $gates($j,1)$gates($j,2)
                    break
		   }
	       }

	     }
             ::DrawGraph::DrawEdge .t1.c2 $xaxis($ingate) [expr $yaxis($ingate)+30] $xaxis($outgate) [expr $yaxis($outgate)-30] 0 1 0
          }
		  
		  
          
            set result [regexp {(out.*)} $gates($k,$l) match sub1]
            if { $result == 1 } {
             set outgate $gates($k,$l)
             set ingate $gates($k,1)$gates($k,2)
             ::DrawGraph::DrawEdge .t1.c2 [expr $xaxis($ingate)+30] $yaxis($ingate) [expr $xaxis($outgate)-30] $yaxis($outgate) 0 1 0
            }
	}
      }
	  
   }
     .t1.c2 create text [expr $canvasWidth-$canvasWidth/2] [expr $canvasHeight-10] -text $module
  }