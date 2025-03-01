--[[
    Iridium
    A Luau disassembler made in Luau
    
    This script is NOT intended to be modified.
    To view the source code, see the 'Src' folder on the official GitHub repository!

    Authors: ActualMasterOogway
    Contributors: GRH
    GitHub: https://github.com/ActualMasterOogway/Iridium/

                                   &&&&&$$$&&&                              &&&&&&&&&&                            
                           &&$&&$&&&&&&&&&&&&&                       &&&$$&&&&&&&$&&&                         
                         &&&&&&&&&&&&&&&&&&&&&&&                   &$$$$$$&&&&&&&&&&&&&                       
                       &&&&&&&&&&$&&$$&&&&&&&&&&$&               &&&&$$$$&&$$&&&&&&&&&&&&                     
                     &&&&&&$$&&&&&&         &&&&&               &&&&&&&        &&&&&&&&&&&                    
                    &&$$$&&&&&&                                                   &&&&&&&&&                   
                   &&$&&&&&&&                                                       &&&&&&&&                  
                   &$&&&&&&                                                          &&&&&&&                  
                  $$$$$&&                      x+++++++++++++xxx                      &&&&&$&                 
                  &&&&&&                    +++x++++++++++++++xxx++                     $$&&&&                
                 X&&&&&               x++++;+x++++++++++++++++++++;;+++x$                $&&&&                
                 $&&&             X+;;;;;;;;;+++++++++++++++++++x;;;;;;;+;+xX             $$$$&               
                 $&&          X++;;+++;;;;;;;;;++++++++++++++xx+;;;;;;;;;;;;;;++$          &&&&               
                        x++++;;;+xXXXx+++;;;;;++++++++++++++++;+;;;;;+++XXXxx+;;;;+++x                        
                   x+xXXXX+++;x$&$$XX$$X++;;;;++++++++++++++;+xxx+;++x$&$$$$$$X++++xxxXxxx                    
                 xX$$$$X$$X++x$$&$X++X$&X+;;;;++++++++++++++++;;;;;;+X&$X;xX$$$X+++$$$$$$$Xx                  
               xX$$$$$x+++++xxxxxxxxxXXX+;;;;;;++++++++++++++++;;;;;;+xXx++xxxxxx++++xX$&$$$$xx               
              xX$$$$$$$X+++++XXXXXXXXx+;;;;;;;;;;;;+++++++++++++;;;;;;++xxXXXXXXx+++++X$$$$$$$x+              
              +xxxxxxxx+xx+++++x+x+++;;;++++;;;;;;;;++++++++++;;;;;;;;;++++++++++xxx+++xxxxxxxxxx             
            xxXXXXXxx+++++++++++++;++;xX$$$XXx+;;;;;+++++++++;;;;;;;;;;;;++++++++++++++++++xXXXXx             
           x++xXXx+++++++++++++++++++x$$XXXX$$X+;;;;;+++++++;;;;;;;;;;;;++++++++++++xxxxx+++++++++xx          
         &x++++++++++++++++++++++x+;+xX$$$$$$$+;;;;;;++++++++;;;;;;++;;++++++xXXXX$$$$$$$$XXxxx+++++x         
       $$$x++xxxXXX$$$XXXxxx++;+++++++XXxxxxx+;;;;;;++++++xx+;;;;;;;++++xxxX$X$$$$$$$$$$$$$$$$XXx+++x$$       
      $$&$xxxXXX$$$$$$$$$$$XXxxx++++++++++;+;;;;;;;;+++++++;;;;;;;;++xxXX$$X+xxXXX$$$$$$$$$$$$$XXxx+X$$$      
     &$$$XxxXX$$$$$$$$$$Xx;+xxXXxxx++++;;;;;;;;;;;;;;++++++++;;;;;;++xX$$x+:++;;xXXx$$$$$$$$$$$$$XXxX$$$$     
     $$$X+xX$$$$$$$$$$$Xx+:.;+xX$$Xxxx+;;;;;;;;;;;;;;++++++++++;;;;;;+xXXx+;;+x+XxXX$$$$$$$$$$$$$$XXx$$$$     
     xXX++xX$$$$$$$$$$Xxx;::;xX$$$$Xxx+;;;;;+;;;;;;;;;++x++++++++;;;++X$XXx+xxXXXX$XX$$$$$$$$$$$$$Xx+x$$$     
     $Xx++xX$$$$$$$$$x+XXx++xXXX$$$$X+++;;;;;+;;;;;;;;+++++++++++++;++x$$$XXxXXXXX$$$$$$$$$$$$$$$$XxxxxxX     
       x++xX$$$$$$$$X$$X$XXXxX$$$$$$x+++++;;;+;;;;;;;++++++++++++++;;++X$$$X$$$XXXX$$$$$$$$$$$$$$$XXxxx$      
       xx+xX$$$$$$$$$$$$$$$$$$$$$$$$x+++++;;+++;;;;;;;;;;;;+++++xx++++++$$$$$$$$$$$$$$$$$$$$$$$$$$Xxx++&      
      +xx+xXX$$$$$$$$$$$$$$$$$$$$&$x++++;+++;;;;+;++++;;;+++;++x+xx+++++++x$$&&$$$$$$$$$$$$$$$$$XXXx++xX      
      +xx+xX$$$$$$$$$$$$$$$&&&$$X+++xx+++++++++++;;;;;;;;+++;;;+xxx+++xxxx+++++xX$$$$$$$$$$$$$$$$Xx+xxxx      
    +xXXxx+xX$$$$$$$$$$$$&&&$x++++xxx++++xxx++++++;;+++;;++++++++++x+++++xXXxXxx+++++++xxxXxx++++++xxxXXxX    
    xX$$Xx++xX$$$$&&&&&$Xx++++xxxXXXx++++xXx++++++;;;++++++++++++++++++++++XXXXXXxxxxxxxxxxxxxxXXXXx+X$$$x    
   xX$$$$xxx++++xx++x++++xxxxXXXX$Xx++++++++++++++++++++++++++++++++++++++++xX$$$$$$$$XXXXXXXXXXXxxxxX$$$X+   
   x$$$$$xxxXXXXXXXXXXXXXXXX$$$$Xxxxx++++++++++++++++++++++++++++++++++++++++++xxxXXX$$$$$$$XXXxxx++xX$$$Xx   
   xx$$XxxxXXXX$XXXX$$$$$$$$$$$xx+xxx+xx++++++++++++++++++++++++++++++++++++++++++++++xxxxxxxxxxx+++xxX$$X+   
    xXXXXxxxxxxxXXX$$$$$$$$XXxx+++xXXXXx+++++++++++++++++++++++++++++++++++++++++++++++x+++xx+++xxx+xxXXXx    
     X$Xxxx++xxxxxxxxxxxxxxx++++++xx+x+++++++++++++++++++++x++++++++++++++++++++++++++++xxXXXxxxxxxxxxX$X+    
     xxxxxxxx+xx+x+xxxxx++++++++++++++++++++++++++++++++++++++++++++++++++++++xx++++++x$$&&&&&$x+xx+xxxXX     
      xxxxxxxxx+x++x++++x+++++++++++++++++++++++++++++++++++++++++++++++++++++++xx++x+$$$$&&$$$$x++xxxx       
       xxxx++x++++xx+++x++++++++x++++++++++++++++++++++++++++++++++++++++++xxx+++++++++x$&&$xx$X+++xxxx       
        Xxxxxxxxxxxxxxxxxxxx++xx+xx+xx+++x++++++++++++xx++xx+++xx++++++++++++++++++xxx$&$$xxxxxxxxxxxx        
         XXxxxxxxxxxxxxxxxxxxxx+xxxx++++++++++++x++xx++++++++++x++xx+xxx++xxx+++xxxx$$&$XxxxxxxxxxXxX         
          XXxxxxxxxxxxxxxxxxxxxxxxxxxx++xxxx+xxxx++++++x++++xxxx+xx++xxxxxxxxxxxxX$$$&XxxxxxxxxxxxXX&         
           XXxXxxxxxxx$&$Xxxxxxxxxxxxxxxxx+xxxxxxxx++++xxxxxx+xxxxxxxxxxxxxxxxX$&$$$XxxxxxxxxxxxxXX&          
           $XXXxxxxxxxX$&&$$$Xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx++xxxxxxxxxxxxxX$&$&$$XxxxxxxxxxxxxXXXXX           
             XXXXXxxxxxxxX$$&&$&&$XXxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxX$&$&&$$$XxxxxxxxxxxxxxxxXXXX&            
              XXXXXXXXxxxxxxXXX$&$$&&$$$XxxxxxxxxxxxxxxXxxXXX$$$$$$&$$$$XxxxxxxxxxxxxxxxXXXXXXXX$             
               XXXXXXXXXXXxxxxxxXxXX$$$&&&&&&$$&$$$&$&$$&&$$$&&$$$XXxxxxxxxxxxxxXxxxxXXXXXXXXXXX              
                 XXXXXXXXXXXxxXxxxxxxxxXxxXX$$$$$$$$$$$$XXXxxxxxxxxxxxxxxxXXxXXXXXXXXXXXXXXXXX                
                  XXXXXXXXXXXXXXXXxxXXXXxxxxxXXXxxxXXxxxxxxxxxxxxxxxxxXXxXXXXXXXXXXXXXXXXXXX                  
                    XXXXXXXXXXXXXXXXXXXXXXXXXxxXXXXXXxXxxxXxXXXxxxXXXXXXXXXXXXXXXXXXXXXXXX$                   
                      XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXxxXXXXXXXXXXXXXXXXXXXXXXXXXXXX                      
                        XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX                        
                          XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX                           
                            $XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX                              
                               $$XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX                                 
                                    $$$XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX$X$                                    
                                          $XXXXXXXXXXXXXXXXXXXXXXXXX                                          
--]]