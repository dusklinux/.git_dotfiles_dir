Some Effects require a solid layer or an image to work, such as particle playground.

you can create shape layers for text layers but only on a new seperate layer, right click the text layer and create> Create Shapes from Text

you can also create masks from text layers by rmb on the text layer > create> Create Masks from Text.

Master properties by putting supported properties in Essential Graphics panal.

Right click on any layer and it'll give you an option for layer style, and this has most photoshop like features like bevel, inner shadow , outter shadow and more.

You can always change the defualt non transpirancy color to any cusom color other than black, i'm taking about when you toggle on transpirancy under the preview panal comp, its usually set to black by defualt, you can change this by CRTL K /composition settings and at the bottom you'll find 'Background Color'> change it to whatever.

to convert audio into keyframes and control any effect based on it - select the audio layer> Rmb> keyframe assistant > Convert Audio to Keyframes, you can delete left channel and right channel and just pickwhip/use the 'both channel' keyframes. btw it'll create it on a new layer select that new layer and UU to unravel on it. 

hand draw/ scribble like write your name and make it animate in the exact way you wrote it by dragging the mouse(it's like animating hand writing but acutally, you can increase/decrease it's speeed after it's all done by UU on the layer to see the start and end keyframes and drag them out or in) - so let's begin on how to create it > create a solid layer> double click on the solid layer in the preview comp to open it in the layer preview panal > select the brush tool from the toolbar above or (CRTL B) > select the brush size and also make sure the 'Paint' Panal is visible if not make it visibile from window> paint> under paint change the 'Duration' to 'Write On', Mode to normal and channels to RGBA(rgb a for alpha)> draw on the layer preview panal with the playhead at the position where you want the animatinn to start from> after you've drawn > go to the effects controls of the solid layer and check 'Paint on Transparent' under the paint property. > go back to the comp preview panal and play the animation. it'll play it. you can press UU to reviel the  starting and ending point of the animatin. 
btw you have to create a solid layer for other effects to work too like 'Audio Waveform' and some others. 

Mattes
	Alpha Matte
	Luma Matte
	Preserve underlying Transparency

Alpha Matte- 
Say you had 2 layers; One- the layer a colorful pattern on it. Two- a rotoed out human dancing. Now you wanted the human to be filled with the 1st layer(colorful patterns) ie you wanted the human's face and body/clotes and everything else to be filled with colorful pattern from the 1st layer. You will need to enable the Track matte Alpha on THE 1ST LAYER (yes the layer with colorful pattern, yup i checked this so yes it's correct) /or you could pickwhip from the 1st layer to the human roted layer(the 2nd layer) and it'll show you the colorful pattern only on the human cutout with alpha layer. and not on the transparent areas. 
	You could also use it in a senario where you only want a moving layer visible if it is in a certain area on the screen ie say you want the a text layer to only show/ be revield if it is inside a rectangle.
	You'd need to pickwhip from the text layer to the rectangle shape layer and don't forget to turn the visibility of the ractangle shape layer back on because the visibility automatcially turns off when used as track matte. and then you'll have the text layer only visible inside the shape. You could toggle the invert option to only be visible outside the rectangle.

Alpha matte inverted -
already mentioned above briefly but here you go again; Say you have a text that you want to have cut out another layer with footage. ie say you want the footage layer to have a cut out in it of the text (punch holes in the footage layer the shape of the text into it) go to the footage layer and pickwhip to the text layer or drop down and select the text layer and then toggle inverted on the side of the matte.

Luma Matte- 
So this works the same way alpha matte works only it effects the luminance channels of the targetted layer ie. It primarely uses the white values to show/reveal the source layer unles inverted using the toggle

Preserve Underlying Transparency - (P.U.T - my own abbrivation for brevity)
Imagine you have a composition with multiple layers, ideally organized as a precomp. This feature works in a hierarchical manner, meaning it only affects the layers that are positioned beneath the layer where it’s toggled ON. It does not influence any layers that are positioned above it in the layer stack.
Essentially, it functions like an alpha matte. This means it will only display its content in areas where the layers beneath it are opaque. For example, if one of your underneath layer is a square-shaped layer with transparent areas around the square, those transparent regions will also render as transparent on the current layer where the P.U.T feature is enabled. In other words, the transparency of the underlying layers dictates which parts of the toggled layer are visible.  
This works by toggling the Grid toggle to the left of matte options on the timeline. it's symbolized By 'T' in the heading bar on the timeline panal. 

Types of Keyframes. 

Linear - (default) icon is diomand shaped with left half filled.  this yeilds animation that is very regid and unnaural, without any momentum gain, also the biggest downside of using this is that in the graph editror, when you switch to the speed graph, and want to move around the squires (keyframes) the keyframes are 

Bezier - icon is cicular with left half filled (select all keyframes and CRTL > Lmb on one of the selected keyframes to convert to bezier and baack from and to Linear) Bezier keyframes allow for curved interpolation between values, creating smoother and more natural-looking animations. you can also CRTL LMB on the keyframe points/connecting points in the graph editor on the speed graph to switch to bezier or back, They use control handles to adjust the curve of the animation; the reason to use this are many, you can do everything you can with linear but with caviat, in the graph editor the speed grapch's connecting points/keyframe point are connected instead of being disconneced as is the case in linear keyframes; this is also the case when you easy easy the linear keyframes, the speed graph's connecting points remain disconnected while with bezier keyframes- when you easy ease them, the points remain conected. 

Eased - icon is a timeglass with left half filled. this is easy ease f9 shortcut. 

Hold - icon is a squire with left half filled. or the icon can also be just pointng an arrow with a squire next to it, the arrow could be pointing left or right, this doesn't intropolate between keyframes but jumps to where the keyframe is at the time of the keyframe. rmb on the keyframe> toggle hold keyframe or use the shortcut CRTL alt lmb on any one of the selected keyframes. 

the spacing between dots on the path of a position property- eg a circle traveling from one corner to the next corner on and on will show a guideline of the path/tregectry of the cicle shape or any layer being moved. this will obviously have to be keyframed to work. for simplicity let's assume the keyframes are linear keyframes (the default ones and not easy eased with custom curves) and are far apart at certain places and closer at other places on the the timeline, the cicle will travel at diffrent speeds depending on the spacing between the keyframes. the pace of the cicle as to how fast or slow the circle will move will be depicted by how many tiny dots there are on the path, if there are a lot of circles cramed in togeter on a line it means the circle will travel slower on that path, if the dots are spread apart far and wide, the pace of the circle travelling will be faster. (btw it's only visible when the playhead is paused) while creating easy ease with custom bezier curves, the dots will be cramed in on the line at a certain area and wide apart at another area, all depending on the manipulated cuves of the keyframes on the speed graph/value graph in the graph editor. 

to change the path of an object in motion, select the layer and when the the playhead is paused, you'll see the dotted line and ALSO the (squire box)points/keyframes in the preview panal. select the pen tool or shortcut G and click on the box/point/keyframes in the preview panal to convert it to bezier path and then you'll have the handles to tug and pull on to change it's path. the thing to note is that if the dimentsions on the position property are spereated, you will not be able to change it's path using the bezier curve handles in the preview panal. because to move around freely in 2d space you need both x and y controls, but when they are seperated, they can only move in any one direction at a time so will not give you the bezier curves or motion path in the priview panal. 

can turn off all effects on a layer INSTEAD OF DELETING THEM USING the CRTL shift E shortcut; toggle the fx switch in the timeline on the layer to which effect/s are applied. 

Project Do NOT's
AE is not a video editor(NLE), it is a compositing software that is capable of animation. Do not edit footage in AE.

Edit footage in an NLE such as Premiere. Use AE for motion graphics and VFX's.

Mp4 sources cause issues in After Effects. Do not use mp4 in AE projects, Convert to Prores 422 or 444 first using Adobe Media Encoder. MP4 is a lossy format & will just make your system have to work harder. It will slow things down because your computer has to decompress the footage to make it usable. Mp4 can also contain codecs that will give issues such as VFR (Variable Frame Rate) footage(Game footage and Go Pro, are most likely sources for this) These are known to cause severe issues with AE. Render all mp4's to Prores first using media encoder.

NO MP3. Use .wav or .aiff audio files.

Do not directly export to mp4 out of AE via Media Encoder. Use AE native render engine.

** Note: A 2 step render is preferable. First export as Prores using AE native render queue, then convert that file to mp4 via Media Encoder.**

Speeding Up Work Flow
If possible work in 1/2 to 1/4 resolution. Change this back to full resolution before rendering.

Set Preview in 1/2 to 1/4 resolution in Preview control panel.

Make sure that there are no other apps running. Including unseen apps in the background that are eating resources. Note: Chrome is super resource intensive and should not be running while using After Effects.

AGAIN Do not use compressed formats in AE; it only slows your system down.

Disable CPU and GPU intensive effects (example blur and glow) in the effects control panel by clicking the "fx" box in the panel next to the effect name OR in the "fx" box located in time line, during your creation process. Important: Turn them back on before rendering.

idk a use case for this leave it as default but good to know nonetheless; To Preserve Frame Rate & Resolution in After Effects- control + K and open composition settings and then under the second tab= advanced tab- check preserve frame rate and then also check preserve resolution, this is for when you nest a comp within another comp and want the new comp to maintain it's frame rate and res. PS the curcial things to note are. 1. the comp into which other comp/s is/are going to be nested should have a resolution and frame rate highher than that of the comp who's resolution and frame rate is preserved. what i mean is, let's say you are nesting a comp "A" (preserved) into another comp "B". Comp A's frame rate should be lower than that of Comp B's for it to work. If Comb B's frame rate is lower than Comp A's frame rate, it will obviously not work when you play the footage from comp B.

You can seperate the demenstions on a postion layer by right clicking and seperating dementions, and you can also just unlink scale's dementions by toggling the link symbol next to it. scale has seperate dimentions greyed out so only toggeling the link symbol works. 

There's two ways of reversing keyframes - first one is at the same place and the second is by copying/cutting it and pasting the reversed version of it at the same/another place
	Automatically reverseing the keyframes at the same place is called Time-Reverse Keyframes which can be done by doing the following; To Time-reverse keyframes- select the keframes and then RMB on any one of the selected keyframes > Keyframe assistant > Time reverse Keyframes. you can also assign a keyboard shortcut to it. 
	
	Pasting the copied keyframes in reverse order is called Reverse paste keyframes which can be done by copying the selected keyframe by CRTL + V then to paste them in the reveresed order; Ctrl + Shift + V or edit> Paste Reversed Keyframes 
	
	
everthing in Ae that is built in or has an option can have a keyboard shortcut asigned to it,	 when in keybarod shrotcuts section> edit> keyboard shortcuts to open the menu, the shortcut to opening it is . CRTL + alt + '  when the shortcuts pannel is opened >

In the new update of Ae you can now copy expressions only on one layer and paste it on multiple layers at once, it'll automatcially determine which property it was copied from and where it needs to be pasted eg, if it was copied from the position property, it'll automatically paste it to the postion property of the the selected layers, you dont have to select the position property on each layer you want to paste it to, just select the whole layer and it'll do it all on it's own. 

Same with keyframes, you can copy keyframes from one layer on multiple properties eg, copying rotation and scale keyframes and pasteing them on other multiple layers all at once thanks to the new ae update. note that the first keyframe will only be dropped where your playhead is at so make sure to keep the playhead at a desired place you want to start keyframing from. 

Copy Expression Only- will only copy expressions can be acheived by rmb>Copy Expression Only or edit>Copy Expression Only. by default it doesn't have a keyboard shortcut but you could assign it to it obviously. 

Copy with Property Links- the expression on the source layer will drive the animation for all layers to which the property links are pasted, it automatcially copies the full animation driven by both; keyframes and expressions applied to the source layer to which it's pasted will inherit all of it, it'll be driven by the source layer ( it's identiccal to paranteing a layer to another layer.). you can CRTL alt C or Edit> Copy with Property Links to copy with property link and paste it on multiple propertieys at once. this also takes into account the comp from which it was copied eg it uses the expression comp("Comp 1").layer("Shape Layer 1").transform.scale

Copy with Relative Property Links - don't ever use this, this does the same thing as copy with property links but it only works inside the same comp because it uses the expreession; thisComp.layer("Shape Layer 1").transform.scale

to find out the duration between two keyframes, alt click the first keyframe and then alt click the second keyframe, then in the info pannel,it'll tell you the duration between the keyframes.(don't have the playhead exactly on the keyframe otherwise it doesn't work might be a bug or something) 

Info pannel is so useful for seeing the RGB values of the pixel where your mouse curser is on the screen and it'll also tell you the exact x and y values based on where your curser is in the comp panal. 

sometimes there are multiple keyframes on a layer with different timings in between them, for instance there's 4 keyframes on the postion property of a shape layer but they are all placed in a way that the movement of the shape layer is faster at times and slower the other times, to make sure the speed at which the shape moves is consistant from the intiial positon to the end position, you'd need to select all keyframes and then > RMB > rove across time. this will even out the timingis across all keyframes and then you could easy ease the fist and last keyframes> then select all keyframes again > RMB > uncheck 'rove across time'. ( Rove Across Time in After Effects is a feature that allows you to smoothly transition from one keyframe to another over a period of time. Essentially, it enables you to create animations with a more natural and fluid movement, rather than having abrupt jumps between keyframes.)

when you create a shape layer by RMB on the timeline > New > Shape Layer. it'll create a blank shape layer BUT the way to understand it is that the shape layer is actually a containor for shapes, so this creates the contanor without any shapes in it, if you select the empty shape layer and draw with the pen tool on it, it'll create a shape within it under 'Contents', you can have as many shapes in one container as possible., you can also just hit 'Q' and then draw a shape on it and it'll be listed under contents.  also fyi when you create a shape layer from scratch ie wihtout a container by either drawing with the pen tool or hitting q and drawing a shape, it automatically creates a containor and incubates the drawn shape under 'Contents', you can stack as many seperate shapes under a shape contaner as you want. also each shapes under one container essentially acts as a layer of it's own by giving you transform options and ALSO blending mode options.You also of course have a master trasnfrom property to move all shapes within a countanor at once. it's at the bottom. 

To be able to change the shape of a shape layer, you need to convert it to bezier path to get the vertex points for you to move around and manipulate the shape of a shape. btw you might not be able to see the vertex points or they might all be selected at once, so first click away using the v tool (move tool) inside of the preview panal and then navigate to the path property by CRTL F on the layer in the timeline panal and click 'path' and you should be able to see the vertex points, select any one of them and move it around. 

the pen tool in the toolbar has serveral options underneath it, most importatnly 'convert Vertex tool' and 'add vertex tool' , you also have 'delete vertex tool'

when drawing a star or a pentagon in the comp preview panal, before relesing the LMB, hit up arrow or down arrow to increase or decrease the star's points, or increase or decresae a pentagon's sides.

Paranting works differently when just paranting vs when holding down shift while paranting (pickwhiping). just paranting doesn't change the initial properites of the child layer, but holding shift while paranting inherits all the current properties of the parent layer. for instance let's say you're paranting A to B , when just paranting A will not move it's positon but when shift paranting , A will snap to where B is. 

enable or disable expression for multiple layers all at once by selecting the layers then RMB>Switches> disable/enable expressions. it can also be done by right clicking on the comp Preview panal and will have the same sub menus pop up.
 
To get keyframes from an expression enabled property, RMB > Keyframe assistant > Convert expressions to keyframes. then I can remove the expressions and work with the keyframes.

To make the playhead loop after playing ie make the playhead go back to the begginning of the timeline/inpoint and play again after reaching end of the timeline/outpoint. 

to loop a footage> go to the project panal (source of the footage in ae) > rmb > INterpret footage > Main> Other options (at the bottom) > Loop > put in the number for how many times you'd like it to loop. 

If you have an inpoint and outpoint set to a portion of the timeline, you can instantly make the inpoint and outpoint extend to the entirety of the timeline by double LMB clicking on the in/out point bar (anywhere on the bar)

feathering a mask does it uniformly across the whole mask, if you want finer control ie control which part of the mask to feather out and how much to feather, use the Mask Feather Tool, it's right where the pen tool is in the tool bar, lmb and hold on the pen tool to list the feather tool and feather away by lmb on the mask insides and creating multiple vertex points to feature at your heart's content. this makes it possible to apply diffrent feathering strenghts on a single mask. this doesn't require for you to use the default feathering property under the mask in the timeline panal, but you could use that in conjuction with the feather tool, the way to use the feather tool is by creating multiple points on a mask and then change the postion of the points, keeping one point far away and points on either side of that farther point; closer to the mask will result in just the point that is far away driving the feather to just that point. 

You can quickly select the sub menu of a drop down right-clicked menu and select the option with just the first letter of the option as long as it's the only option with that starting letter. for instance if you're on a position propertey and want to seperate dimentions, you can RMB> hit S instead of selecting seperate demintions with the mouse. 

Layers in the timeline can have two names, one is which is it's actual name from the project panal aka it's source name, the other is when you rename it to something else in the timeline, the way to toggle between the two names is by clicking on the heading that catogorizes the particular tab of Name of the layer on the timeline, (it's right under the search box for searching certain properties) so the heading can be either of two things - 'Layer Name/Source Name'. 

you know how you can toggle one of the 4 icons on the bottom left of the screen to show certain tabs or hide them on the timeline : like if you want to show the blending mode options or hide it to make more space for other elements on the timeline, well, you don't have to rely solely on the bottom 4 icons to toggle certain tabs, you can RMB on any of the tabs themselves right below the search bar in the timeline panal, such as on the 'Layer Name/Source Name' and then individually select which of the tabs you want visibile and which one you wnat turned off. so the way to do it is by RMB on any of the tabs under the searh box in the timeline panal and then > Columns. this gives you finer control over what you want and what you dont want.  

You can move a descimal point on a property by CRTL up arrow or down arrow or just hold LMB and move the cursor/mouse up or down, say you're moving up a number and you want	 finer control over the numbers, hold down CRTL and up/down arrow but first select the number you want to have finer control over. 

always, always! continuasly rastorize your pdfs/ vector/ illustrator/ photoshop layers to maintain there resolution and clarity even when it's scaled infinately

to change the defualt blue interface color of ae do the following ; CRTL f12 then when the conosole opens up in the preview panal, lmb on the top hamberger menu(the three horizonteal lines stacked up) right next to 'Console' on top of the preview panal> 'Debug Database View'. then search for the following > 'Enable_Theme_Colorizing' > check it (if chekcing option isn't available just type manually type 'true') (true) > go to edit> prefereence> appearance> 'hightlight color' and change it. 

alwasy switch back and fourth between the speed graph and the value graph to see which one better suits the senario/situation.

freezeframe a layer to act as a picture, RMB on the layer and make sure the playhead is at a desired spot. then RMB> time> freezeframe. 

outside of motion blur toggle or the force motion blur effect, there's another way to add motion blur and it works both on 2d and 3d layer movements, first of all toggling the motion blur symbol in the timeline pannel is requried for it to work > and it is the comp shutter angle, so CRTL K to open up compt settings> Advanced> shutter angle right under motion blur sub menu and crank it up to exagurate the motion blur. 

if you have multiple changes made to a layer like you've had effects and masks and other things applied to it and messed around with it's transform properties, and now you want another layer to inheret all the effects, you can quite simply dublicate the layer with all the effects and then select the dublicated layer > while holding down ALT, drag and drop the new layer from the project panal onto the timeline panel all the while the dublicated layer being selected, or you can also drop it onto the comp preview panal while the dublicated layer is selected.

depending on the image you are working with you'll need to set the bit color of the comp accordinly, if you are workign with a regular image from the internet, you don't need to do anything because the comp will defualt to 8 bit, you can see what bits per channel it is (bpc) its usually at the bottom of the comp panal with either 8 bpc/16/bpc/32bpc. higher bpc will result in slower timeline because it'll hog up resources to render.(if you film in prores log, it defaults to 10 bpc so which ae doesn't partuculalry support but you can use a higher bpc like 16 bpc and it'll use all the colors from it ) btw 32 bit float is used for hdr footage. 

if you want to change the way the expression editor looks, you can change everything from Edit> preference> scripting and expression, in line error notification, to auto brackets to tab width to color to so many other things like preview panal expression error at the bottom, , almost every little detial pertaing to expressions is customizable. 

VR footage:- if you take a 360 image using the google streetview app or anyother app that will let you take sphear photos, those photoes will be flat and distroted when importing into ae, so to correct for that, you'll need to do two things, first add CC Environment and then the comp will turn black and you wont be able to see shit, so you'll need to add a Camera to be able to see your layers and then you can animate the picutre and everything, it's truly a great feature to move around and zoom in and out, ideally creat a solid layer and add the effect to it and under the effect properties link to the 360 layer. Note that there is also an inbuilt script under windows>VR Comp Editor.jsx, this is at the very bottom cuz it starts with V so it's alphebiticlaly arranged. and then select 2d edit, 3d edit is almost never used. the script uses the effect "vr sphere to Plane" and not cc enviromnet. also the script automatically adds a camera. ps. i think cc enviromnet is for still images that are 360 degree images as opposed to 'vr sphere to plane' effect being for video footage shot in 360 degrees with something like those special cameras. there are effects made particualy for 360 degree footages/ VR(virtual reality) footages, use those effect because those effect compensate for edges when moving around using a camera, with regular effects, things look distorted in certain areas particularly at the edges. so use vr effects, there are a ton of built in vr effects just search for them in the effects and presets panel. 

The backward slash symbol next to rasterize and shylayer in the timeline pannel is nothing but anti-alising it's labelled "quality and sampling" when you hover over it with the cursor, it either makes the edges strickly opaque , toggling it makes the edges half opaque/trasnparent. this is espicially useful for when multiple layers are on top of one other with their edges overlapping too and creating an unwanted artifact. 

sometimes you need ever finer control over the placement of keyframes, and you're limited to placing them on frames and not inbetween frames, but with toggling one inbult option, it'll allow you to place keyframes inbetween keyframes for even more control over it. so to enable it, go to the graph editor, chose the second symbol at the bottom next to the eye symble, the second symbol is a panal with 3 option in it, depected as lines. and when you hover over it its labbeld. 'Choose graph type and options' and when you click it, go to the last option lablelled Allow keyframes between frames. and toggle it.	

Color Grading: to be able to see a color graph of the image or footage you're working with, use Lumetri scope panal, enable it from the windows tool bar at the top, and then also use lumetri color effect to change the colors of the footage. at the bottom of the lumerti scope panal, there is a wrench icon to list more optons to view the color details of the layer.

when drop picking a color with a the drop picker tool, if you hold down CRTL while picking the color it'll sample a larger area to give you an average of the colors, espically good for green screen color picker, you can visbily see the drop color picker increase in size when hodling down CRTL and lmb 

If you want to make a shape/arrow always point in the direction of a path, use auto orint path by RMB on the layer> Transfomrm> Auto Oriont> and then check oriont along path. You need to copy the path from either a hand drawn path as a new shape layer and then toggle down to the path property of it and copy it, then proceed with pasting it on the position property of the arrow you want to orient along the path. shortcut key for auto oriont panal is Ctrl+Alt+O

Json file, csv, txt, tsv or any other data file doesn't necessoraly need to have their properties linked to a source text, you can drag and drop the data property from any of the data files onto the comp preview panal and it'll appear there as text but note that it'll automaticlaly turn the text into a guide layer so it wont render unless you right click on it and uncheck guide layer. 

You can change the value of any data file within a text editer and then save it (i'm taking about the source file that was imported into ae), it will automaticaly update the values in AE. 
 
CSV FILE, you can set this up in any text editor like the defualt windows notepad also works in excel. csv aka Comma seperated values works by creating a text file with csv extention and then writng the data as follwos eg
	name,favcolor,total_limbs
	dusk ,red,4
and then importing the csv file into ae and then into the timeline> twearl down the properties then pickwiping the source text of the text layers in ae to the corrosponding values of the data file, now there's another thing, when you pickwhip from a source text file onto the the properties of a data file, the paranting breaks if you remove the data file layer from the timeline panal, so to circumvent that issue, you need to right click on each of the data propety and select 'copy expresson only' and paste that into the source text box of the text layer, this allows for the expresson to reference the text from the project panal's data file instead of the timeline's datafile so if you delete it from the timeline it'll still work because it's using the project panel's file as source file. btw it uses dataValue() expression to work.

TSV FILES. Tab seperated values, same for this but it's seperated by tabs , this is generally how spread sheets are exported. they apparetaly default to exporting in the tsv format. but of course you can also set this up in any text editor like the defualt windows notepad eg of how it's formatted
	name	colors 	numbers
	dusk	red		3
	kim		puple	2
	bryan	blue	1
	susan	green	4

let's say i wanted to refer to it using the expression:- dataValue([]) method, i'd need to find the index value of the property i'm looking for, so the way you'd do that is by going vertically so the zero column is name the first column is colors and the second column is numbers, so if i wanted to get' blue from bryan, i'd have to input [1,2] , so colors would be 1 and then starting from red as 0 index purple as 1 index and blue as 2 index. so that's how i arrived at [1,2] so pickwhip to the datafile and then .dataValue([1,2]) first vertically then horizontally is how you get to the value [1,2]

JSON files- javascript object notation.  
this is similar to how objects are formatted in javascript but this requires every text in the file to be in double quotes.

eg json formating
"planet" ={
	"earth":{
		"land":{
			"soil":{
				"tree":"leaves"
				}
			}
		}
	};

planet.earth.land.soil.tree.toUpperCase()

object formatiing
eg : const planet ={
	earth:{
		land:{
			soil:{
				tree:"leaves"
				}
			}
		}
	};

planet.earth.land.soil.tree.toUpperCase()

dataValue([]) = is an expression used to get a certain data using indexs. eg i wanted to get "leaves" from the code above, i'd need to do this, first go to the text property, then pickwhicp to the datafile > at the end of the path place the expression .dataValue() and within the paranthesis enter the index in an array, like this. [0,0,0,0,0] since the object above doesn't have multiple properties it's all 0 index if it had multiple properties, i would have had to use 1 and 2... and so on indexes. btw when you right click on a data file's propety and copy expressions to link it to a text layer, the dataValue([]) expression is how it does it. and you can see it and learn it that way too if you have any issues understaning how this works. 

KEYBOARD SHORCUTS

LL - automatically list wav form audio visualizer in the timeline pannel for layers with audio. 

Caps Lock- temperaraly disables comp preview and makes the time line so much smoother and faster to work with, espically with a lot of complicated layers and precomps. so use this when things feel slugish. 

Ctrl shift E - will remove all effects on a layer. 

Alt Shift P/T/S/R - will drop a keyframe for postion/opacity/Scale/Rotation at the playhead for the selected layer. 

CRTL Shift P/O/R = to manually enter a value for each of the transform properties. yes O for opacity
	crtl shift S reserved for 'save project as'

I and O - to navigate to the begenning of the layer/ layers selected, it's basically the inpoint and outpoint of layers. if multiple layers are selected and they are of varying lengths. when you hit I - it'll go to the earliest in point of the layers and when you hit O, it'll go the outpoint of the layer that ends at the very end and who's length is the longest and ends at last. 

J/K allows you to move to the previous/next keyframe and also MARKERS on the entire timeine across all layers but the movement to the next/previous keyframe is congingent/predicated on the keyframes you want to jump to being visibile. so long as the keyframes are not visible ie they are not revaled/expanded; you're not going to be able to jump between the keyframes.

B and N for setting inpoint and outpiont on the timeline, it'll be set on where the playhead is (workspace)

		CRTL Shift X = to trim comp to work area.

(DONT' USE THE FIRST ALTERNATIVE KEY COMBO IN THE FOLLOWING OR IT'LL GET CONFUSING)

[crtl left/right arrow] OR *****[(FN)PAGE UP/PAGE DOWN]****** to move the playhead forward or backward by one frame, yes both combinations perform the same function.

		([crtl left/right arrow]+ shift) OR *******(FN) PAGE UP/PAGE DOWN + SHIFT******* to jump forward or backward by 10 frames. (hold down fn key too for pg up and pg down depending on the keyboard and only if page up is a modifyer key that requiers the holding down of shift)

crtl alt left/right arrow or *******(FN)HOME/END(LEFT AND RIGHT ARROW WITH FN KEY)****** - to move the playhead to the starting of the ENTIRE TIMELINE or the end of the ENTIRE Timeline

		(fn)+Shift+Home/End(left and right arrow with fn key) to move the playhead to the starting point of the WORK AREA or the out point of the WORK AREA.
		
CRTL Alt Shift Left/Right - allows you to move to the in/point of ALL LAYERS ie even if no layer is selected, and you have layers scattered across the timeline at diffrent time and say the playhead is at the begenning of the timeline, it'll allow you to move to the pressing the key combo and the right arrow will move the playhead to the closest in/out point of a layer and then the next in/out point. this will happen regardless of weather the layer's in point is outside the work area on the timeline.

Alt Left/Right arrow = allows you to move the selected keyframes right or left by one frame.

		Alt Shift Left/Right arrow = allows you to move the selected keyframes right or left by 10 frames.

Alt (fn) page up/page down(up/down arrow) = moves the selected layer forward or backward by a frame. 
		Alt (fn) page up/page down(up/down arrow) + SHIFT = moves the selected layer forward or backward by 10 frames.

		Alt (fn) home/end( left/right arrow)  = pushes the selected layer to the starting postion/end position of the timeline.

ALT[ or ALT] to trim off the starting of a layer and the end of a layer.

		[ and ] to bring the trimmed layer to either bring the layer start to where the play head is at [ ,or to bring the end of the layer to where the play head is at ] 

CRTL up arrow or down arrow to select the next layer in the timeline 

		CRTL Shift up or down - selects multiple layers up or down. 

CRTL ALT Up/Down - bring the layer forward or backward aka to move the selected layer a layer below or a layer above. 
	
		CRTL ALT Shift UP/Down arrow will make move the selected layer/s to the top/bottom of all layers.
	
CRTL A - select all layers.

		CRTL Shift A = deselect layer or layers. 

numbpad 1,2,3,4,5,6,7,8,9 to selct layer cooresponding to thier index.
	
		numpad numbers Shift to select multiple layers like shift 1, shift 6 to selct the 1st and 6th layer

CRTL \ to Hide ae's top bar (essentially make it go full screen.)
	
		CRTL 1 to hide the toolbar
	
CRTL L/CRTL Shift L = allows you to lock and unlock selected layers. (unlocking combo unlocks all locked layers, you cant select locked layers.)

Up/Down/Left/Right = will move the layer in any direction by less of a pixel but this is also depended on the zoom level of the comp preview panal.

		Shift Up/Down/Left/Right = moves the layer in any direction by an apparently visble amount of pixels, this is varialbe based on how zoomed in or zoomed out a layer is superfically in the preview panal, not the property but just the zoom level in the preview panal. 

CRTL ALT T to enable Time remapping. (mostly only works on precomps and comps and not on layers)

CRTL T = will alow you to draw the bounding box for text and then write the text on the screen,  if you press CRTL T agian it'll switch to vertical typing and agian will switch back to horizontoal typing.

		CRTL ALT Shift T will just drop a text layer for you to type in wihtout a bounding box

CRTL ALT o (ou not zero) = Auto oriont/ oriont along path. 

Shift + ? = auto make the comp preview window fill the panal screen. 

CRTL Y = solid, 

CRTL ALT Y = adjustmant layer. 

CRTL ALT Shift Y = null

G - Pen/Mask tool 

CRTL B - erase tool, you can only erase a layer in the layer panal on both a video and stills.
	crtl b also toggles between eraser tool, clone stamp tool and the brush tool. i have the erasor tool as the main thing so i remeber it don't change that. 

Q - draw shapes, keep pressing Q to toggle between diffrent shapes, you can tell which shape is selected by looking at it in the toolbar.

W - To select the rotatate tool from the toolbar, you can straigt away rotate a layer from the preview panel with this tool. 

CRTL ALT Shift G/H to fit the layer to compt width or height, 

		CRTL ALT F to stretch and fit the layer to the comp resolution even if it has to distort and original x,y ratio of the layer ie if the layer is squire shaped but the comp is rectangle shaped, it'll stretch the layer to fit the comp.

CRTL K to open comp settings. 

CRTL Shift K - to turn SELECTED text into caps/small letters.
				and also
CRTL Shift K - to bring up keyframe velocity menu for the SELCETED keyframes. 

The ENTER next to the num keyboard acts diffrently than the ENTER on the regular keyboard. the Numpad ENTER acts as an okay or finishing of a text layer, while the regular enter key drops down a 	line. It probably has more applications. 

to rename a layer- hit regular ENTER. 

` (tilda) key to bring the hovered panel into full screen. 

; (semicolen) to toggle zoom on the timeline panel to see each frame.
	-/= (minus and plus keys on the keys uptop) to zoom in and zoom out. 

(comma and period) ,. to zoom in and zoom out in the preview panal. 

' (apostrophi) to show screen's safe zone. 

		CRTL '(apostrophie) to show a detailed grid.

		ALT ' (apostrophie) to show a grid with bigger squires on the screen for guides.

Crtl Alt '(apostrophie) to open keyboard shortcuts settings.

CRTL  R to show rulers

CRTL shift D to split a layer. 

CRTL D to dublicate a layer.

Shift plus Num(4,5,6,7) to add markers on the comp, or you could also drag in the marker icon from the further right of the comp on the timeline pannal to the place you want the marker to be placed. there's a marker icon on the farther right of the timeline panal for you to drag and drop on to the timeline. 

		* (astrick) to add a marker on the timeline, either on a layer or on the comp, if you have a layer/layers selected, it'll drop a marker on the layer but if you don't have any layer selected, it'll drop it on the comp where the play head is at. 

	to make a marker disect or divide in two parts to place an inpoint and an out point for the marker, as previrously said, astrick * to place the marker on a layer and then ALT + LMB and drag it to right to drag a marker out. 

CRTL ALT Home - to center the achor point on layers, can select multiple layers and then do the key compbo to have each layer center the achor point , propotionally to each layer and to there center. 

		CRTL Home - center a layer's anchor point to  the center of the comp. can also be done to bring multiple layers to the dead center of the comp.

Y = allows you to move the anchor point using mouse in comp preview panal

		CRTL double LMB on the achor point icon in the toolbar at the top to center it into the selected layer.
	
		ALT double LMB on the achor point icon in the toolbar at the top to center it into the center of the comp.

CRTL ALT C = copy with property links and then just paste the keyframes. (property links is when you want for the layer you copied from to contol the property of another layer to which you pasted the property link); although it works exactly as pickwhiping, it's better cuz it defines the comp and not just thisComp expression to refer to the source layer like pickwhiping does. so copy with property links works across diffrent comps and is great way to mitigate any future errors from having multiple comps that are cross referensing.

Crtl C - to copy layer or keyframes
	crtl shift v - to reverse paste keyframes. 

ALT LMB on the stroke or fill box at the top with the shape layer selected. to toggle between diffrent options like storke/none/gradient/liniar gradient. 

When using the gradient fill option, a line will appear on the shape on wihch the gradient is applied, the one end is for one end of the color and the  other end of the line is for the other color gradient. 

Double LMB click on the shape tool in the toolbar to make a shape layer the size of the comp. the shape that is toggled in the toolbar is what will be drawn. star/rectangle/circle..etc

C = toggle between three seperate/ different camera options(only applicable while a layer is 3d, doesn't require a camera to function but layer needs to be 3d)

when creating a 3d solid layer and you want to add extrution and depth to it, switch to one of the two 3d engines - advanced 3d or cinema 4d and the option for exturion will become visibile on the layer property, btw if you want for the edge color to change (the extruded width) use a stroke and change it's color. 

ALT Shift = (yes equal to is part of the shotcut key) = will remove expression(you have to select the particular property for which you want it disabled.). if you hit the key combo on a layer without expression, it'll create expression on it. try it out. so it's a toggle switch between removing expression or creating one. (btw it wont disable the expression it'll in fact REMOVE it! so use with caution)

		ALT LMB on the watch icon on a property  - to go into the expression text field on a property (if an expression already exists, twerl down teh property instead of clicking the watch icoon because that will remove the expression) 

		E+E to bring up all expressioned properites on selected layers. 

U+U to bring up all keyframed properties on selected layers. 

S+S to solo selected properties on layers. 

CRTL ALT Shift LMB = to hide a selected propoerty, eg if you have multiple things listed, like position, scale , trasnpirance, i can hit the mentioned keys to hide the selected property

CRTL ` (tilda key) to unravel all properties on a layer and hitting the combo again will colapse it all. 

E to bring up all the effects on selected layers. 

M to show mask on the selected layer. 

F on a masked layer = will bring up the feather property. 

CRTL Shift H = will turn off the visibility of the layer's bouding box, which means if you have layers that have bounding boxes such as a shape layer with the box around it, or a null with that red squire, if you want to hide all that distraction you can turn it off using the shortcut/ it's the same as toggling off/on (the icon rectangle with top left corner cut) underneeth the preview panal, it's right next to the toggle transiprancy under preview panal.  

P, R, T, S, A to bring up position, rotation , opacity , scale, Anchor Point . Can Hold down shift while pressing the aformentioned keys to bring up multiple properties at once.  

CRTL Shift C to precomp selected layers.  

Shift +/- = allow you to cycle through each blending mode quickly. Shift Plus+ / Minus - you can cycle thorugh the blending modes,  select any layer and without droping down the blending mode you can straigt away start cycling through the blending mode using the shortcut. 

CRTL F = to quickly search for a selected layer propertiy in the time line search pannel. or just CRTL f without any layer selected to search within all layer's properties. PS. you can search for multiple properties all at once by seperating them with a comma, for instance you can search for the opsition propoerty on the selected layer or all layers and then if you also want the scale property you'd need to write them up in the following format - position, scale 

F9 to add easing to selected keyframes.

ALT LMB and drag = to space out keyframes evenly on a layer select the keyframes > ALT LMB and drag them out. this also works with multiple layers stacked on top of one another and manually staggernig/using a plugin to stagger the keyframes by 1 or two keyframes > then to space out the keyframes by a desired number of frames, you need to select all starting or ending or even both keyframes at once> then holding down ALT while draging any one of the selected keyframes to the right or left on the timeline and it'll automatically space them out propotionally.

CRTL ALT Shift N = to open a new comp preview viewer side by side, you can lock one of them to always show a certain comp. 

GREEN SCREEN
There's serveral way of getting rid of a green screen but there is an effeciant way. use the obselete effect - color key, because it is really quick to render, and it will get rid of most of the green then, use simple chocker, then use the real effect-keylight, and then use advanced spill supresser

Advanced spill supresser has two drop down menu options under method - standard, and ultra, when selecting ultra, it'll allow you to sample the green color from the footage. 

color range - very rudamentary and not recommanded for keying but could be used for other instances other than greenscreening. 

key cleaner = cleans out the edges of green screened subject and also bring back some details into the eges. 

Composition Border- this can be applied in limited ways, one way to do it is by creating a blank shape contanor by RMB on the timeline and > new > create new shape layer and then applying Composition Border preset to it. 

key light (1, 2) - the master greenscreen effect- you should ideally use two or more key light effects stacked up on one another to first remove the majority of the green screen then expand the edges of the subject using one of the existing sub settings under keylight that works similar to the simple chocker effect and then when you see just a thin outline of the green screen around the subject, stack another keylight on the layer and this time you only have to worry about a limited area of green screen and it's better this way, btw sample a large portion of the green screen by holding down CRTL when drop picking the green color. and also toggle through diffrent viewing ooptions to see how the keylight has worked, more often than not, you'll be able to see so many leftover areas that need to be rectified in other view modes on the keylight effect. 

Here's a practicle application of the keylight for my particual videos. apply keylight> pick green screen color by CRTL clicking the area for larger sampling of the green screen. then swtich to the view mode of screen matte. 
now go to the other screen matte property and clip all the black away by cranking it up to 90's 
then crank up screen shirnk/grow to around 50-70 and then check if the main subject is being clipped out. then switch the view mode to intermidiate results. to not have it use advanced spill supression built into keylight,(yes, the view modes aren't just there to show you how the keying is working, it actually changes the way things are keyed so it's important to switch to intermidiate results.)
then place a new fresh keylight effect and this time you'll only have to worry about the narrow edge of green screen surrrounding the subject, this is the profecossional way of doing it. 
then select the green edge outside of the subject by CRTL seleting the green area. then proceed forward with the follwoing. 

you should mainly use the following viewing modes under keylight. 
source - when first picking the green screen color. 
screen matte - to see it using the balck and white lens of what is keyed out and what's not.
status - this is an exaguurated version of all that is keyed out and all that's not, this is perfect for fine tuning. 
final result- and this at the end to see how it looks. 

to color match the contrast and brightness, sometimes just lower the opacity of the subject intead of messing with brightness and contrast. 

to key out more of the left over green screen (view as screen matte/status to see better) go under the screen matte property (yes there's another property called screen matte and it's called this regardless of what viewing mode you are seeing the footage as) then play arond with the clip back sub menu under it. don't crank it up too high, around 20-30. 
finally add a tad bit of screen pre blur to make it look natureal. 

EFFECTS

Normal object tracking - first select the layer for which you want to have something within it tracked, then go to the tracker panel,(enable it from the windows tool bar at the top if it's not already enabled) then ideally create a null layer and then under trackers - 'Edit Target' select the null layer as the target, and then select Track motion and then check off position/rotaton/scale or all and then select the part of the footage you want to track by placing the binding box around the area of intrest. the small box is for the actual thing to be tracked and the outer bounding box is for allowing ae to search for the tracking object, note that the bigger the box, the more time it'll take ae to process the footage and track it.  and then either play it one frame forward or play the whole thing, ther's an opton for both in the trackers panal. and then when its' done apply it. 

Face Tracking - first, double click on the layer and open the layer panal, then draw an ovel shaped mask on the face, this only works when you have a mask drawn on the face and then after the mask is slected go over to the tracking panal and you should see 'Method' under tracker panal and drop it down and select face tracking (detaild features ) and then just hit play in the tracking window and ae will work it's magic and after it's done processing, it'll drop all the keyframes under the layer properties,  under face track points. then pickwhip seomthing to one of the many sub properties such as nose/ eye/ mouth and it'll follow it. 

to be able to track liquified effect onto a part of a face - it can be tricky to get it to follow one part like squishing a nose or making the nose longer like pinoccio, so this is how you do it, either make an adjustment layer and drop the liquify effect onto it, or just drop the liquify effect on the layer you want to manipulate, then drop down into the effects properties and find 'Distortion mesh offset' (it'll have two numbers - x,y) then pick whip/ parent it to the part of the face that's been tracked already, like nose/eye/or what ever. and THEN do the liquifying manipulation, if you warp the footage around using the liquify tool before parenting, it'll move around and not be alighned perfectely after parenting because it jumps around based on the anchor point. so first parent and then warp the footage.  CRTL + draging the mouse up/down or left/right to make the liquify circle to effect the footage smaller or bigger.

Stabalize Motion under tracking allows you to make the tracked point be at the center point of the comp viewer. it essentially allows you to track a point in the scene and have that be stabalized eg you could track a moving face and the tracked face will be at the center of the screen. or say you had a shot of a person dancing and you wanted for the dancer's head to be perfectly in one spot even though the person was moving around, you could track his face/head and have the entire video move around except for the head. it's pretty neat.  

solid composite- it fills up the transparent parts of a layer with a user set color in the effects panel, but only to the point of the bounding box of the layer, and not beyond it. 

Grow Bounds - allows you to artificially grow the bounding box of a COMPOSITION layer, it doesn't actually expand it but makes effects applied to it act as thoough it's a larger size than what the bounding box of the COMP layer suggests. I've tested this on an imported transparent layer with solid compositie applied to it AFTER grow bounds effect, you can increase or decreasee the value under grow bounds to see the effect, this can particularly be used for glow effects to make the glow not have a hard stop/edge where the true bounding box ends, the grow bounds will allow the glow effect to be shown further than the bounding box. 

Stroke- Stroke effect actually has a very useful other application other than highlighting text, which is- it automatically draws an outline on any mask, so for example say you wanted to draw an outline on a person (yes even a moving person) and make it glow- first roto out the person, then go to the top panal layer>autotrace and then check workarea and alpha channel and then hit okay (if it's a moving person use 'work area' instead of 'current frame'), delete everyother mask other than the major one it creates, or you could also keep all the masks, now there are two ways of going forward to achieve the same result, one is to drop the 'stroke' effect on the same layer and SELECT the major mask for the property of effect stroke,mask that outlines the person, and animate it's end point/brush size/ what color. voila! and drop the glow effect on it or turbulannt displace effect on it. second way to do it is to first create a new empty shape layer by rmb>new> shape layer, and then with the play head at the begenning copy the mask/s from the roto'd layer and paste them onto the shape layer while the playhead is at the begeniing of the timeline. then add stroke on it it and check all masks,check sequencually.then increase or decrease the size, the color is also under the stroke effect. 

Stroke /Write on - lol this is the old way of highlighting texts. just draw a shape layer with the pen tool as a stroke and then toggle one of the blending modes and animate it using trim paths. 
 
Audio waveform/ Audio spectrum - you can choose a soundtrack and link to it using the 'audio layer' property under the effect then go ham with the customization, you can even change the starting and ending poistion of the waveform in the preview panal by dragging the starting point and also the ending point to your heart's content. if you want to have a particualar shape around which you want the waveform to show itself, you'll need to create a mask and then set it to none, then under the 'Path' property drop down selct the mask you just created. you can also stack these up on top of one another and copy with property links on the first effect and paste it on the other,for the properties you want to be diffrent and not take the property values from the first effect disable expressions for it by LMB on the equeal logo to disable expressions for it. 

Fyi- for most effects which have an option to apply on a certain path; create a mask and then set it to none > slect the mask for the 'Path' property under the effect. 

Foam- allows you to create bubbles, similar to blowing foam bubbles from that toy i used to play with as a kid lol

cc Bubbles - creates round cgi bubbles whose colors depend on the layer to which it's applied, if the layer is a rainbow, the colors of the buble will be all over the place/colorful. if applied to a solid with just one color the bubble will inheret just that color. 

Liquify - to warp an image/video and keyframe them, great for creating fire/ portals/ making somone look funny, have a long nose. and so many more applications for this effects. 

Puppet Pen tool - is great for animating and bending a shape or any layer by dropping pins on the layer in the comp preview panal and keyframing them. it's in the tool bar above. you can do so many things with this such has animating hair, flag waving, and so many subtle movemtns that would be a pain in the fucking ass to animate using the path property. 

Roto Brush 3.0 - is great for selectivly extacting a part of a video, before you do anything first make sure the preview resolution is set to full and then proceed. so the roto tool, this is in the tool bar next to the erase/ and puppet penn tool,  >  double click the comp preview panal and it'll open the layer comp panal right in the comp preview panal. and then select the roto brust tool, then drag over the part of the footage you want to roto, with your mouse, then adjust the edges using ALT and LMB then play forward and backward and keep an eye out for any divergent from the path intended to be roto-d by pausing and adjusting the edges on the fly, the green part at the bottom will indicate how much is done processing, you can also constrain the inpoint and the outpoint at the bottom of the compt privew windwow by selecting the range (note that this only appears after the roto brush has ben drawn on a frame and then it'll show you the progress at the bottom of the comp as to how much has been rotoed out, use this to only roto out the part of the footage you need and not the whole thing because that's wasteful and increadbly ineffectient), when you're happy with the result, click on 'Freeze' at the bottom of the comp preivew window then, then thats it. go back to the main comp and you'll be able to see the alpha channel and the rest as black/trasnparent.

Find Edges - allows you to create outlines of any layer/footage based on it's brightness/color values. You can dublicate layers and then apply the effect to one layer then use one of the blending modes to overlay on the origional layer to create outlines on top of it, you can add the glow effect to it so it makes the outlines glow or subtle turbulent displace or both, or change the color of the outline by adding the tint effect.  You can do it in two ways, one is to use the blending mode and set it to multiply or use the effect cc composite which is exactly the same as blending mode but the good thing is ti'll only effect one layer and and not every layer underneeth it.  a great effect to create using find edges is on top of fractol noise

CC MR. Mercury - allows you to create and simulate water flowing, this is very 3d like and has so many applications including but not lmited to blood flowing, spraing water, or anything with liquid phisics. 

CC Sphere - allow you to create a sphere out of a flat image say you have a flat image of the world as a map, addign the cc sphere will turn it into a globe and allow you to spinn it as if it were a 3d object. pretty cool imo (rotation property under the effect not the transform rotation)

CC Composite - NOTE!! it doesn't always appear to work and that's because it needs to have the 'rgb only' property unchecked (it's checked by defualt) so this effect is the blending mode effect, it allows you to only affect one layer as oppsed to all layers below. this works similar to dublicating a layer on top and toggling one of the blending modes, the best thing about this is that you can stack multiple cc cmposite effect on a layer and each one of those effects will act as a diffrent layer, so you can have unlimited amount of effects all on one layer that gives you an identical effect to having unlimited number of layers.

Create Nulls from Paths- allows you to do three things. makes the vertexes on a path follow nulls by creating new null layers at each vertex point, note that you have to have the path property selected before clicking Points follow nulls. and the second thing it does is the opposite of the first one, this one makes the nulls follow the vertex points on the  path. and then the last one is trace path; it does exactly what it says, it tracs the path of the shape and then crates a null that has the path animated, you can essentially link another layer's postion property to the newly created null position property (it has an expression on it but parent to it still, it'll work) and it'll animate, you can also oriont along path. (let me be clear on what the last option actually does; say you have a squire and you want another layer eg an arrow to animate on the outline of the squire, then select the path property of the squire and trace using the create nulls from paths and then when a new null is created with it's position property animated already albeit using an expression, just parent to it , you can also change how fast or slow it's animating by using the keyframed prperty under 'progress' on the null layer, just hit UU twice and it'll show you the keyframed property and then change how fast or slow you want to make it or easy ease it or what ever)

3d effect on any static/2d image/ next level parrallex effect- 2 ways to do it= first one is by importing the image into phtooshop and then > Filters > Neural Filters > Depth Blur > Turn off focus Subject and eye ball the depth> at the bottom select - Save on a new layer> invert the deapth map cuz black is going to be interpreted as the opposite of what it should in AE.  then save as psd and import into AE> then there should be two layers> one the deapth map and the other the original image> then apply displancement map on to the orignial image and then select the depth map layer and then also drop down and select masks and effects under displacement map effect, then on the depth map layer> apply fast box blur and increse it a little and then play with displancemtn map effect on the origninal image.  Second way to do it is to use ae's plugin= deapth scanner, use it and every thing else is the same- displacement map fast box blur and so on. 

note that the photoshop method only works on still images, but the ae deapth scanner works on videos as well as images and it's fast af, generates a deapth map in realtime. 
  
This is so fucking cool! it's a transition based on the deapth of the picture, It looks insanely cool in tandom with other effects. but just this effect alone is also incredbly cool- so here is how you do it. get a deapth map of an image you want to transition from. so if you want to transition from layer 1 - layer 2, get a deapth map for 1, then to the layer 2 add the effect "gradient wipe" and add select the deapth map layer for the property "gradient layer" under the gradient wipe effect. also check masks and effects for good measrure. then play with the transition property under the gradient wipe effect. in total you shoudl have 3 layers for this to work layer 1, deapth map for layer 1, and layer 2 (to which you're transitiong to with the gradient wipe effect applied to it and with the deapth map selected), Make sure the layer to which you are transitioning is on the top, in this case that would be layer 2. by defualt it looks at the luminance of the current layer, it doesn't understand depth perse but it understands luminance so when you create a deapth map, it's nothing but black and white values. so its nothing but lumincance.

Making flowing water/wavy hair. or anything wavy/ like flag/or fire or  fabirc or anything with wave warp= below is how it's used in detail. 
Wave warp = allows you to make flag like animations and a bunch of other things. like a river flowing or water flowing, the way to do that is by having a white solid and then drawing mask on the whole layer by selecting the rectangle shape in the tool bar and then selecting the mask option next to the shape option in the toolbar, and then double clicking the rectangle shape to perfectly place a mask on the entire layer. then double click one of the sides of the newsly created mask and it'll let you change it's dimentions/size. then make the height narrower/shorter and it'll look like a river flowing by increaing the wave width. There's an option in the effect properties called pinning, and it'll essentially allow you to make the water not flow as much from one of the sides, like it'll gradually start flowing in a certin direction and it's powerful and all from just one effect.  
Make this thinner for animating hair. it's so pefect. to make the hair thinner on one end you can hold ALT on one of the vertex's of the mask and then pull out the bezier handles to give it a gradual curve.
I can stack the wave warp on top of one another and offset the animation a little to give it a natural look and not make it seem like CGI. You don't have to have it be the whole size of the comp, just have to find the looping point of the hairs and then create a comp of it and then loopOut the layer to make it render faster and work efficiently. 
This can also be used as a great matte layer for bringing something into view or maybe even trasition to reveal the bootom layer by having the top layer disapear from the wave or smoke.
You can also dublicate the first layer with all the effects and everything and then add bezier warp to it to give you finer controls over the full size and shape of the layer, and then you can cut through the first wave and have it diverge in two seperate directions if it's smoke by using one of the blending modes to cut through the layer by using Silhouette Alpha.

Bezier Warp- it'll give you the bezier handles and controls to change the shape of a layer you can bend,elongate, squeeze, stretch using this effect. ,you can put this on an ajustment layer above effects and it'll only effect the custom drawn size of the adjustment layer. this is so useful, you can rewatch the video by jake in motion - titled easy 2d smoke & hair in after effects. 

Mesh Warp - creates a grid that doesn't render. but that gird can be used to warp the footage on which it's overlayed, note that you can only select the intersection of the grid to move aruond and warp the footage, you can increase how many intersections there are by increaaseing the rows and columns numbers whithin the mesh warp effect. 

corner pin - this is everthing that cc power pin does but less, so always use cc power pin instead and i'll explain what cc power pin does below. 

cc power pin - this allows you to manipulate the prespecive of a layer, by giving you 4 points for each cornor of the layer and it also gives you guide lines to see how far you can streatch it, you can lmb on the edge of any of the guiding lines and pull and push to change the prestpective that way, now comes the part about vecor layers, for vecor layers, things work diffrently because vecotor layers (text layers/illustratior layers/shape layes) use comp space instead of layer space so when you apply cc power pin to it, the 4 pins are attached to each cornor of the entire comp as opposed to the bounding box of just the layer. (eg if a text layer is smaller in size than the entier comp size, which in 99% of cases it'll be) the cornor pin will be applied to the edges of the comp rendering the effect essentally unusable, so to circomvent that issue you can fix it in two ways. 
1st way is by prcomping the text layer and making the size of the precomp in which the vector layer is, exactly the size of the vector layer. and then going back to the main comp and applying the cc power pin onto the precomp. the 2nd way is by using 2 cc powrer pins, first apply 1 cc powerpin and disable the effect then move the 4 pins to where you want them to be (to the 4 cornors of the vector layer), then enable the effect and check 'Unstretch', doing this shoudl fill up the entire preview windows with the vector layer, then Dublicate the first cc powerpin, (don't create a new cc power pin cuz you need the dublicated one with it's points already shifted.) then uncheck 'Unstretch' on the second effect. and you can move thigns around, use the transform effect to move the whole vector layer around in the comp rather than using the postion of the layer in the timeline because timeline trasnform breaks the effect. 

Photo Filter - is great for applying from a set of presets under the effet's property has warm tones cool tones and so many more. alos has natureal/real world tones. 
  
Advanced Lightining- allows you to add a lightning bolt, or electricity jumping current. Okay this is so cool - Let's say you have a logo or an eliment you want the lighting bolt to interact with, you can either have it affect the alpha channels of the layer. the effect is applied to it by adding cc compositie after the advanced lighting and then unchecking the last option RGB only/ or just check composite on original on the advanced lighting layer lol, neededn't add cc composite, or if it's applied on a solid you can add mask eg a circle and the lighting will move around it and internect with it like its there. it's actuallly so cool to see. jake in mortion ae effectsf for more. 

Coloroma - to give a footage a tripy look , or just one color look like turning it to a certain color, play around with it for so many more applications

Turbulent displace- makes it dreamy or can lower the numbers to just effect it in small quanityes to make as though just the edges are animating, boiled edges. 

roughen edges- roughens the edges, has serveral other options like spiky and rusty. can also draw an outline on the subject to which the effect is applied, the outline can be of a user defined color from the properties of the effect.

Minimax- will turn the layer blurry based on it's color. you have to use it to understand it. it'll make it blobby not blurry. 


Camera lens blur- is increadbly good at making the blur as natural as it gets by turning the bright spots into a pre selected shape from a list of 8-9 shapes like hexagon, triangle, circle and many more.(these shapes are natually present on out of focus lights making this effect realistic) The best thing is that it lets you use a depth map that's been exported using the depth map feature in photoshop or just using the deapth map plugin in after effects, it's slow to rennder but it's well worth the exoprt time. 

fast box blur- makes the edges glow/HALO, adds blur and makes edges softer of a shaper layer, renders fast but is not realistic. it has iteraltion as an option (which means how many times you want the blur applied to it ie if you have the blur amount to 10 and iterations to 2 the blur will work as though it was blured out twice which means it'll act as though 20 on the amount of blur)

Gaussian Blur - is about the same as fast box blur with one less option ie iteration, they both have the exact same effect on how it looks and render at the same pace, since they are both gpu accelarated.

audio spectrum/ audio waveform- to create a waveform visulizer to the beat of the sound. 

drop shadow- allows you to create a drop shadow, there is an even better way of doing this, by dublicating the layer/comp then adding the fill effect to it and sending the dublicated layer backward, then adding fast box blur to it annd then messing around with the scale of it, can also add turbulent displace, or find edges.

radial shadow - is so much better than drop shadow in some ways, you can move the light source on the preview comp and it'll cast shaodaws accordingly. 

cc spotlight- casts not just a spot light but if you have a layer with alpha channels/transpirancy, you can select that layer under properties 'get layer' and it'll cast a shadow/spotlight in the shape of that layer with transpirancy.

cc light rays - works great, it's like lights from the sun in a forest coming through gaps in the trees. but the pre built third party free effect god rays by crate is so much better. 

cc light burst 2.5 - is so much better, very similar to light rays but better in some ways. also slow to render you can see the render time of each effect by looking at the bottom at 'frame render time' i think this effect might work similar if not identical to god rays, except this renders so much slower. 

cc page turn - obvi turns page  BUT ALSO allows you to choose a seperate layer for what you want the back side of the page to look like under properties 'Back Page'

cc smear - is so much better than the liquify tool for dripping liquid effect. select the from point and the to point by dragging the points in the preview panal and then animate the reach. You just have to add multiples up this effect if you want more than one drippin of liquid effect. liquify might be better lol

cc scatterize - turns the layer to which it's applied into dust. It mostly effects bright areas or atleast brighter areas are what are visible.

Light Sweep, is actually great at bringing to life some elements on the screen, its very easy to animate using keyframes, it gives the impression of a light source, and reflection and much more, and the best of all is that it automattacklly only effects the alpha channels of a layer so it helps sell the effect even more. also the traditional way of doing it was creating a solid white llayer adding a mask to it to just the are you wanted to be affecdted and then also matting it to the layer you wanted it to effect and then playing with the feather of the mask and path and then adding one of the blending modes and messing with the opacity of it.


optics compensation- gives a fish eye effect or can do the opposite of fish eye too, both directions. 

cc lens - similar to optics compensation but with few more features. good for transitions. 

cc bend it - allows you to bend an object in either direction. left/right. sometimes when you bend an object and the bounding box is right up close to the edge of the object you're bending, in that case use the effect 'Grow Bounds'- this effect grows the bounding box artifically without affecting how the shape looks or stretching the shape, the thing to note is that grow bounds should be applied before the cc bend it effect. 

chromatic abberation- makes it shift it's color channels RGB. 

S_WarpChroma - this is a paid effect but god damn is it worth it, pirate it and see if you can find it. this is fucking amaizing, this is chromatic apperation but the defualt when applied looks increadble!!!! 

shift channels- shifts rgb channels of a layer. this is mostly used for spliting rgb of a layer, here's an optimal way of doing it. first pre comp the layers or don't if it's just one layer then apply the effect to it, then choose 'Full off' for all three underr take from red , green and blue, leave alpha as it is, dont' change that. then dublicate it twice, so now you shoudl have three layers with the effect applied to it, for each of them select 'take x color from r/r/b' each with just one color with other two set to 'Full off' then when you have done it for all three layers with rgb colors for all thre layers. for the first two layers on the top select the blending mode to 'Add' and then INSTEAD OF moving the layers around using the positition property under transform for each layer, use the effect offset to not have weird blank pixeals on the edges, after you're satisfyied with how the chromtatic abboration looks, use the effect 'Optics Compensation' to give it an authentic chromatic abberation look. you can customize the angle and hwo much from center is being spread apart.    

Mirror- will mirror the current layer to which its applied, it's usually out of the preview window, so drag it in from which ever edge it's at, usually on the right edge of the preview windows, and you'll only see a round anchor like icon to drag it using. when it's dragged in sufficiately inside of the preview panal, you'll be able to see the entire reflection/mirrored image of the layer. btw mirror ALSO mirrors the layer with it's effects applied to it, so that's pretty cool. 

Black and White - gives you more control over each RGB values, you can increase/decrease the contrast of each color channels and also tint the whole image to a certain user defined color. 

Brightness and contrast - this allows you to do two things, blow out the highlights or tone them down using the brightness slider and the contrast slider makes the bright parts of the layer even brighter and the darker parts even darker giveing you a more contrasty layer. 

Tint - It's important to understand how this effect works, it first desaturates the entire layer and then turns all the shadowey parts of the layer black and the highlights to white, then you can map the white to a certain color of your choise using the color picker. same with the blacks. You can also roto out a certain portion of the layer and then apply it to just that and change its color to something else. and maybey feather it out and also add glow to it if you want. 

Fill - buckle up cuz this is a lot more usseful than you thought, first off let's get the defualt function of the effect of the way, when you apply it on a layer, it'll fill the entire layer with the color that's selected in propetiy of the effect, now here is the interesting part. you can selectivyly apply the fill to a certain portion of the layer by using masks, draw a mask on the layer to which the fill affect is applied and then set the mask to none in the timeline pannel, then go to fill's propeties and selct mask 1 or all masks. and it'll only fill up the the masked porttion of the layer while also keeping the other parts of the layer uneffected and still visible. , you can also feather out the fill mask for gradual fall off. 

Tritone, Hue/saturation , Leave color, Luma key , CC Toner, lumetri color, are some of the effects to manipulate color and brighness. 

Tritone - allows you to indipendennaly change the highlights/ midtones/ shadows of a layer.

CC Toner - This lets you do 4 seperate things that can be achieved using 3 sepearte effects all from just this one effect so this serves as a swiss army knife allowing you to choose between 3 settings which essentally act identically as the Fill effect, the Tint effect, the Tritone effect only it is bundeled with one extra feature that is exclusive to this effect. the thing to note is that the three settings are slightly renamed so it's important to understand which one is which and, when you first apply the effect it defaults to 'tritone' under 'tones' property, which is named appropriately so no confustion here, now the other two options under 'tones' are named diffrently. the 'Duotone' under 'tones' acts exactly as the tint effect while the 'solid' option acts as the fill effect. the other option named 'Pentone' is the extra option, it gives you even finer control over several aspects of the layer based on highlights, brights, midtones, darktones, shadows. . With CC Toner, there is a property to allow you to blend it with the original, which other efffects that are standalone in there application don't have. so this is where this comes in handy, but this is limiting in one way, which is that it doesn't have the masking feature that only lets you fill in certain portion of the screen using the fill effect. so there's a time and place for this effect. 

Hue/saturation - allows you to change a certian color range in a footage/layer. great for changin eye color and many more things eg change eye color/ select the eye color by holding down CRTL and then selecting a larger area of color annd then even manually enlarging the color range in the efffects panal. then if it's effecting things in the footage outside of just the eyes, you can dublicate the layer and remove the effect on one the dublicated layer and drop it below the layer with the effect, then roughtly mask out just the face and it'll work as intended.

Grid - to make squire grids and cricle grids. the important thing about this is how the grid is spaced out and how squired off or rectangally it is and you can do this in the following ways. Corner Point - this will let you freeball the height/width of the grid squires based on the xy values of the conor property beolow.
Width & Height Sliders - this will let you do the same but will mention width and height. on the slider and will be sperated on diffrent submentu propertyies. 
Width Slider - this will uniformly scale up/down the grid and give you perfect squires everytime. 
 for circle grids use the gausian blur/fast box blur and then individual curvers with alpha selected and the three pointers on the graph brought to the middle method. to achieve cicles. and various other interesting shapes. alternatively you could also use simple chocker instead of individual curves but simple chocker effect only works on layers with transparency 

CCparticle systems 2 is 2d and cc particle world works in 3d space.Things that can be done with cc particle 2- taperd stroke, ribben simulation, the sun shining, rocket being propelled,fire, smoke water hoes,rain and so many more. this is truly a powerful effect.

radio waves - allows you to create an endless loop of circles by default,it essentially creates circules in side circles and them scaling up/ zoomiing in from the center. which gives the illusion of you traveeling inwards, or the hypnotizing effect, you can obviously change it from circles to any shape, to even stars, squires, or what ever else you might want you can make the corners roundeier too. it's easy on the resoursercs and renders quickly. you can also make it rotate on its own and it'll rotate each shape indipendennaly and offset it from the other so they are slighly offset from being allighned perfectly and it gives you amaizing results. the way to rotate is under the 'Wave motion' propeerty and twearl it down until you see 'Spin' and change it's value. you can also fade them out towards the end by changing the 'Lifespan' value, you can also have it fade in from the center or even fade out, this can be achieved by changing the values under 'Stroke' - fade in/ fade out. , it's exptreamly costomizable, anything you want can be changed to it, from stroke width to the shape of the circle or any shape animating to fade out, to duration, to spacing in between them to so much else. Okay this is increadble!!! you can create custom path and it'll create the hypnotizing animation/echo effect on it, the way to do it is by changing the 'Wavetype' from the defualt Polygon to 'Mask', then draw a custom mask path on the same layer with the pen tool and then Twerl down the 'Mask' Property and select 'Mask 1' from the default which is 'None'.

Leave color- it allows you to choose a color you want to stay in the footage and removes everyother color in the footage annd makes the rest black and white. this is a great tool for creaing a footage with just one color in it and the rest black and white. 

cc rainfall- simulates rain

cc snowfall- simulates snowfall. 

mocha ae - great for tracking and quite easy to learn, watch jack in motion's tutorial on it. 

warp stabilizer- stabalizes a shaky footage. and works great to add motion stablizing in post to a shaky footage.

cc vignette- need i say more? lol  

Checkerboard- to make a chess board. 

Venetian Blinds - this essentially makes parallel alternating lines with in alpha channel/transparnecy set to 0 in alternating way. it's great for so many things. , you can add fast box blur to it and make it look like crt by stacking two of these up and rotating one by 90 degrees to make it effect both horizontolly and vertically 

VR digital Glitch = allows you to add this glitch like comptuer corruptped effect on a footage. great for transition and other things. 

Add Grain - adds grain. , there are many presets that are so much better than the defualt one, some of the presets make it look like it was shot on a professional camera under dark lightning. after you've chosen the preset, there is another property - 'Application' if you want it looking realistic, you're going to to twrel down the options and then drop down the blending mode and choose 'Film' film will only show the grain in darker areas and not in lighter areas. Film is the most realistic way of adding grain to a footage. this is extreamly costomizable by twriling down the options under application even further and tuning if you want grain added to any one of the rgb channels in shadow areas or lighter areeas. some presets that are great are these 
• Kodak Vision 200T (5274)
• Kodak Vision 800T (5289)

noise. - ads noise. 

Linear Wipe- dont' sleep on this, it's increadbly vercitile annd powerful effect, you can use it to create gradiennts. helps elimantte hard edges, and ofcourse it can also be used for transitions but dont' use it for that that often. can also be used to compare the color or an eliment of two diffrent layers by having one layer be half visible and the other layer be half visible to, you can shift the line where the layer stops being visible around and back and fourth to better see the differnece between the two layers. 

posterize time - effect and also an expresion posterizeTime(); makes the frame rate user defined on the applied layer/s . 

Posterize - this is a diffrent effect alltogether, it's to create a segmented layer/pixilated but it's not the same pixilated as moasic effect, it's kinda artisitic style segmentation, it reduces how many colors a layer can have rangingg from 0-255. and it cann only be applied in one direction not both horizontially and viertically like pixals but more like just vertical with roationg property to change its direction. 

Mosaic - it allows you to lower the resolution and make the layer to which it's applied, look blocky and pixilated, it has great artisitc applications, can also be used for bleeping out mouth swearing movemtns, or creating old crt text with pixilated edges. 

radial wipe or trimp paths for pie chart animation or semi circle.

Warp is great for making curves, swiggly lines. and much more.  ,it's great for creating some very fun texts, too, just apply on an adjustment layer or even on the text layer itself and play around with warp settings. 

Turbulant Noise - it's the exact same as factal noise and renders quickly, the only thing about this is that it doesn't have the option to cycle the same noise on the screen every few seconds aka it doesn't have the 'cycles' option/ property under the effect. 

Turbulant Noise- to add dust and scratches by lowering the brightness and increasing contrast. , this has so many other applications espicially for artifacts.

fractal noise - can do so many things with this, can create dust and scratches by stacking up the effect, or just one effect by messing with the contrast and brightness of the effect. the key to creating grain is by REDUCING THE 'SCALE' property under transform of the fractal noice property by reveleaing the nested options under the effect's propety. and playing around with contrast and brightness, (lower brightness and increase contrast) add fast box blur if you want it blurry. You should also stack two grains by dublicating the already created layer with grain and then adding invert effect to it and using one of the blending modes. this works wonders on making it look mysteriious. add posterizeTime(6); on the sub property that will animate, eg if you are gonna be using evolution property by usign the time*1000; then use the posteriize time on it instead of using the effect after the factal noise effect. be effeicient. You can also use the random seed under fractol noise to animate the grains by using posterizeTime(6); followed by random(10000); btw there's an evolution and cycle option that allows you to cycle the way the noise appears on the screen every few seconds (user defined in 'cycle')  

Invert- inverts the layer's colors. use the 'Channel' proeprty under the effect, and change it to r/g/b/alpha or anything else at your heart's content. 

Spherize- allows you to create a ball like extrution effect on any layer. 

Ripple - creates water drop like ripples on the layer. need to crank up the radius for it to show. 

cc ripple pulse- a diffrent version of the ripple effect

cc drizzle - kinda like rain drops impac on water, similar to ripple

shadow/highlight - great for automatically bringing down the highlight and cranking up the shadows to produce a balanced footage. looks great. 

cc ball action - turns the whole layer into small balls to which its applied. great for pixelated type effect. you can also scatter those balls and create a tranistion from it, it's great, you can also apply it to a small eliment that is on a layer of it's own and have that disintegrate and obilitrate into balls. the great thing about this effect is that it creates 3d balls that also respoinds to actual cameras inside of ae. it's so great. 

cc star burst- so fucking great, makes for great 3d type stars that are rushing towards you/ make you so as though you're traveelling fast through space with debirs around you. apply it to a solid layer. you can tint it/glow/deepglow/4 color gradient/ cc lens/ optics compensation/ chormatic abberation. 

Bulge - same as spherize but with a lot more controls and costomizations.

force motion blur on objects that normal motion blur doesn't work on like videos.

echo - to create a trail of the shape/object. 

cc wide time - is similar to echo but has a few fore applications, ways to use it is by applying it on a layer, then using cc compositite effect after cc wide time with rgb property toggeled. (to bring the original unaffected layer over the layer to which cc wide time was applied) you can also add tint before cc composite to change the color of the trail, and even add glow to it, or turbulannt displace. btw this effect can also be used to show case the path animation, by using the 'forward steps' property under cc wide time.

glow - to give it a halo type of an effect, you don't need nothing else, just stack them up and having diffrent threshoold and radious values to bring the object of focus to life. 

Curves/ levels- allows you to play around with the contrast, colors, alpha channels, individual RGB colors. and so much more. very powerful for color corrections. 

cc radial scale wipe - is best used for transtion, it essentially makes a circle bigger with transparncy in the place where the circle is and reviealign the layer underneeth. 

Wave Warp, is a cool effect for simulating hair movvemnt or water flowing or fire burning. you can use it in tandom with mirror to have both sides of the (eg triagle) flow at the same time and be symmetrical. looks good when symentrical. 

CC Glass-  cool for creating petruding shapes, bevel like effect/embossing/debossing. you can do it both ways:- take the layer you're applying the effect to as it's own source layer to effect it or You can also set the source image in the effect's panal to another layer through the droop down menu to have it work that way as well. you can change the property option to alpha if the image is trasnparent on parts that doesn't need contacting the shape 

CC Plastic - works similar to the CC Glass but is a little different in the way it looks 

CC Blobbylize - this makes it look like a blob or liquid metel if the colors are metalic, or you could also make it look liquidy depending on the colors,  this is pretty cool, so you can set the source layer's alpha channel as it's displacement layer, and then mess around with other properites on the effect. You can add the offset/motion tile effect BEFORE the blobbylize effect to make it seem a lot more reflecty and dynamic, it looks like there's a light being shown on the blob and that it's reflecting, obviouslyi animate the offset. it looks very 3d but it's an illusion that looks convincing.

Offset - this just repeats the image if you move it away from the screen, 

Timewarp -  this is similar to optical flow/ frame blending when the footage is shot in low fps such as 30/60 and you want to slow it down by 5 times for slow motion, or maybe you just want a 24 fps footage look like 60 fps footage, this works wonders on the footage. it create extra frames in between existing frames.

	there is another way to achieve a similar result and tha tis by toggeling the frame blending option in the timeline. it's the option to the left of the adjustment toggle option, it's icon is that of the film used in older camera (nitro cellulos sheet, it used to be black/brown in color), when you hover over it in the timeline panal it's labbled 'Frame Blending - Interpolates frame content by weighted blending' clicking it inserts extra frames into the footage to make it apppear as though it was shot at higher fps so clicking selecing the checkbox for the layer onece will swich to frame blending, LMB it again will switch to pixal motion, pixel motion is easier on the resources as it doesn't need to generate the full frame but just for the areas where there's a pixel change, you can tell how much extra time it ads to rendering by looking at the frame render time at the bottom of the timeline panal, tooggle it on if it's disabled 

Displacement map - You have to first understand what this does, it's very simple when you realize what it does. the displacement map moves pixels around on a layer based on several user specifed properites. so what do i Mean by that? let's break it down so a retard like you can understand what i mean, With another effect like Offset- when you shift the x/y values of the effect it moves all the pixels on the layer uniformely and symetrically and therefore retaining it's visual depiction. Displacement map does exactly the same thing but it doesn't do it uniformely it does it based on a certain user selected property, so there are several options under displacement map effect, the first and foremost and the most importart property is the displacement map layer, this means which other layer's color/alpha/luminance properties you'd like to take from. alternatively you could have the current layer as it's own displacemenet map, in most cases (as many as 99.99 cases you'll only need to use the luminance property and not rgb or alpha).  for a grayscale/ black and white displacemtn map; the thing to note is that white areas of the map will displace the pixels more and black areaas won't effect the target layer at all. black and white displaace the targeted layer in opposite directions while gray doesn't move at all. 

Motion tile - this is much more powerful because it can mirror the edges, making it seem a lot more realistic in it's attempt to expand the image. 

CC RepeTile - this dublicates the layer and puts the dublicated layer right next to the original layer, it can dublicate it until it fits the entire comp and beyond and in both directions- vertical and horizontal, let me further explain how this works, say you have a small circle the size of 1 or more pixal in a comp of 1080p, instead of creating 1080x1920 seperate layers for each of the circles, all i'll need to do is use this effect on it and it'll automatcially do the work for me, it'll place the dublicated pixel right next to the original one and until the whole comp is filled with it. I can do the same with small squires to create a grid type effect or even checkerboard type effect. 
shape layers that are hand drawn have a repeater property in the same many as where the trim paths is. LMB on the 'Add' option right next to the 'Contents' under the shape layer > repeater > this does somethign similar to cc repetile.

Luma Key- allows you to remove the lights or darks from a layer. 

Extract - allows you to remove any of the chnannels from a layer, like rgb alpha luma dark. - increadbly powerful. eg you can remove the darker areas and only keep highlighted areas then ADD THE GLOW effect just to the highlighted area, then have the dublicated layer underneeth it without the extract and glow effect. 

If you want to quickly and perfectly remove Just the blacks from a layer use the effect 'Unmult' aka Alpha From Lightness (Unmult), it combines several effects to remove blacks perfectly and it's prebuilt into ae. 

Set Matte - allows you to set another matte to the affected layer, this way you can have the timeline matte option use one matte layer and set matte use another matte or use the same layer for both, one effecting the alpha channel the  other effecting the luma channel. 

Morphing instrauctions.
first get the two footages (the one that's going to turn to another)  might need to roto it if it' a film and not a png,then do this for both layers individually. Layers > Auto Trace. choose Alpha generally but you could also use luma if that's what you want, it'll automaticlaly create masks. Sometimes it creates more than 1 mask, so see which mask has the vast mejority of paths and delete the other masks that only have like a dot or something of a path. Copy masks from both layers and paste them to the other layer. so now each layer should have both masks, it's own mask path and the mask path of the other layer as well. ps, Yes, both layers will need to have 2 masks each, So in total 4 masks. Add the "Reshape" effect to both layers and then select source mask(from)  and then destinaiton mask (to), for one layer it will be in one order and the other layer it'll be in reverse order (i mean the source mask and desitnaiton mask, because one will turn into another layer and the other layer will turn from another layer) then hold down ALT until you see the + symbol in the comp preview window, and then add multiple paths. this will ensure fluid and intuitive transition. do it for both layers, and then set up opacity for both layers one going from 100- 0 and other from 0-100, overlap the keyframes so that they are top of one another and transition perfectly without seeming jittery 
then set the 'Percent' under reshape effect from 0-100 and set key frames. 
OR
suprisingly you can also use the liquify tool to morph into diffrent objects. like set keyframes on the liquify tool and then morph into the 2nd layer by distorting and then playing around with the opacity, and then doing it the other way around as well, distort the first second image to first image's size and apporixmate shape. but the first method of using the reshape effect is easier because it does the distroting part all on it's own excpet for choosing with ALT and dragging the starting and ending point manually. So i just tried it, it's actually yeilding better resulsts and it's suprisingly quick and easy. 


lock, auto orient real worlkd camera, 




CAMERA
what the actual fuck!!! how did i not know this??? having multiple cameras on a timline actually serves an increadble purpose!!!, you can quickly cut to a diffrent angle on a 3d object or even a 2d layer depending on what the active camers on the playhead. let's say you have a dice facing the side with 3 on it and it's slowlly moving upward, then half way through it you can ALT ] to cut the camera layer at the playhead and then create a new camera pointing the other side with it's position keyframed and animating already when it switches. this makes for such a cool look it's crazy!!! https://youtu.be/zgMHWFolli8?list=PLzf-EjFJ11qQ2LXKV_PGR8NXhSkghHxf4 this is the link if you want to watch it. 

deapth of field (DoF)/ focus distance/ aparture/ blur level are all disabled on every engine other than the Classic 3D engine, this might change with future updates but as of now the following engines don't support a lot of things including effects on layers and also dof. 
Advanced 3D
Cinema 4D

CRTL ALT shift \ = to look at selected layer when they are out of frame, this can be used when there are multiple layers and each layer needs for the camera to look at them at a certain time so you can click each layer and hit the shorcut keys and drop a keyframe, then move forward in time and do the shorcut again while selecing a differnt layer and drop another set of keyframes, so on and so fourth. 

CRTL ALT shift C = will open the setting window to create a new camera  layer. 

A = will show the property 'point of interest' it's the keyboard shortcut for it. 

for the purpose of your own sanity and convinience, always use a two node camera unles you're retarded. (there might be an occational instance where the application of one node camera is what is needed but id think there is.)

Using nulls changes how cameres work in AE. 
Here are the following ways in which a camera can be used in Ae. 
1. Camera Alone
2. Creating a Camera Layer and then creating a Null layer and parenting the camera to the Null layer. 
3. Create orbit Null. (note that a camera layer has to already be created and selected.)

One node Camera- so this works much like how a real world camera works and it's very limiting, so if you spin around the subject will quickly move out of the view finder, it's like when a camera being mounted on a tripod and panning around, you can look around the world but the main subject will not stay in the view findder. 

Two Node Camera- will create one additional point/node. which is point of interest. So now the camera will always point towards where the point of interst is, it'll lock it's view finder to the point of interest which means when you spin around, the whole camera will spin in order to keep the subject in view. It'll auto orieont towards the subject regardless of where you move it in 3d space. but the limitation of it is that you can't make it spin around an object(orbit around it), i mean you could theroretically do it but it would be so fucking painstaking that you'd want to KYS, so this is where a null comes into play. the reason to alwasy use a two node camera is because of when you use a null to parent it it'll automatically snap to the point of interest not to mention the fact that it has a point of intrest. so all in all, it's more flexible with what it allows you to do and it's easy af to use, almost identical to one node with 1 extra option ie point of interest. 


There's two ways of creating a null with the camrera parented to it and both serve the exact same purpose, 1st way is by giong to the toolbar> Layer> Camera> Create Orbit Null, this will automatically create a null, turn it into a 3d layer and parent the selected camera to it, place the null exactly at the 'point of intrest' of the two node camera (or if you have a one node camera, it'll place the null right infront of it, you can still change it's position easily by moving around the positon of the camera, if you move aruond the null, because the null is parented to the camera layer the camera will move along with it, so just move the camera and you'll be able to change the distance between the null and the camera but just use a two node camera if you don't hate your self.) and also rename the null to 'camera x orbit null'  the 2nd way is by creating a Null layer, toggling the 3d switch and paranting the camera to it,but this method wont automatically place the null at the point of intrest,(it's not even all that necessry,in some cases)so both these ways do exactly the same thing. now the purpose behind this whole thing is as following, it unlocks certain camera momvements that are so much intuitive to work with, eg.
this makes the camera spin around the null(which could be place right in the center of the 3d object eg cube), it pins the anchor point onto the subject(eg dice) and the camera will spin around that dice and the camera's position will physicaly move (let's say you have a dice as the subject, the camera will spin around it like the earth revolves around the sun, this way it'll reveal other sides of the dice and the numbers on the dice) the most important part about this is that you can manually click and drag on the null within the preview panal or alternatively you can preciecly change the position of the null whitin the property menu under the parented-to null layer at any time.  lol it's called orbit movement i just learned that. 

when using the 'C' key to animate the camera, both the Point of interest and position for the camera is changed so keyframe both of them when starting out.  

Toggling 'C' three times will cycle between zomming in on the z axis/ x,y axis / rotating or spinning around the object of focus. 

the following camera settings can be changed at anytime during the timeline, it's not fixed to just one value, it's keyframable. 
 
Focus Distance is the distance at which the focus is at, you can automatically link the focus distance to the subject in several ways. 
Top Tool Bar > Layer > Camera > .... sub-menus. 
1. Link Focus Distance to Point of Interest - so with a two node camera, the you get a point of interest that is placed right infront of the camera by default, but you can change it, so if there's multiple layers varying in their zPosition you can shift the point of interest by either manually dragging it in the preview panal or through prorperties and then the layer to which PoI is the nearst will be in focus, you can play around with the apertture to make the blur outside of the zone of the DoF (deapth of field) stronger or just straight up incresse the blur strength through the blur property. 

2. Link Focus Distance to Layer - so this works similar to auto focus but with the subject locked. you can select a layer to which you want the camerea to always focus on. this requires for you you to select two layers one is the the particular camera layer to which you want the desired/targeted layer to always be in focus and the 2nd one being the targeted layer you want in focus. then proceed with toolbar>layer>camera> link focus distance to layer. 

3. Set Focus Distance to Layer - will allow you to set the current focus distance to the selected layer. requries both the camera and the targeted layer to be selcted at once like for the previous option. But with this particualr option, if you move the camera around, it wont stay focused to the layer, it'll move out of focus, this is partiucally for helping with keyframing the exact focus distace to a layer. (pro tip: add a keyboard 
 for this task)

reason for null layer for camera - 1st reason is when you have alredy added keyframes on the propetieis of a camera layer and you don't want to mess around with it to break the perfectly created path/zoom in/zoom out. you can create a null and parent the camera layer to it and still have the keyframed propertyes work on the parented camera layer,and now you can further customize the oritontation/position/or what ever with on the null layer without a chance of ruining the path or what ever of the paranted camera layer. you shoudl theroteically also be able to do this infinately, like after adding keyframes on the null layer, you possiblly could then parent it to another new null layer and further customize the camera placemnet. idk why you'd need it though. it shoudl definately be possible.

F-stop is the same as aperture. the smaller fstop leads to shallow deapth of field while a larger f-stop leads to broarder DoF
f-stop doubles every twice the number , the starting f-stop is all you need to remember which is F 1.4 so f1.4 lets in a lot of light, while twice that of it - f2.8 lets in just half as much light and f5.6 lets in half as much light as f2.8 so on and so fourth. 

Aperture is the size of the hole to let the light into the lens. it's the smae as fstop

Deapth of Field aka DoF is the range of subject in focus. anything outside of focus is outside of DoF

Zoom - zoom into the subject. 

Focal Length - is the distance the lens is from the sensor, a focul length of 10mm would make the lens an ultra wide lens, while a focal length of 100mm would make it a zoom lens. 

Film size represietns the size of the sensor. 

Angle of view - a wider angle of view will result in an ultra wide frame, while a narrower angle of view will lead to a zoomed in frame that is focused on just the are af intrest as oppopsed to all encompossing. 

3D camera focal lengths:- also known as zoom levels. 10 mm is zommed way wayy out as opposed to 200mm being wayy wayy zoomed in. 

Focal length is a way to measure how zoomed in or zoomed out a camera lens is. The higher the number, the more zoomed in the lens is.

So here's what each of those focal lengths mean:
18mm - This is a very wide angle lens. It captures a really wide field of view, making things look smaller but fitting a lot into the frame.
20mm - Also a wide angle lens, just slightly more zoomed in than 18mm.
24mm - A moderate wide angle lens. Still gets a nice wide view.
28mm - This starts to get closer to a "normal" field of view, similar to human vision.
35mm - Considered a standard or normal lens for things like portraits and general use.
50mm - A classic focal length that is very natural looking, great for portraits.
80mm - Now we're getting into telephoto territory. This lets you zoom in more on your subject from farther away.
135mm - A more powerful telephoto lens that really magnifies the subject.
200mm - This focal length allows you to get tight shots of subjects from a long distance away.

you can animate the camera in three ways, one is by just directly manipulationg the camra properties and keyrameing them, the sencond is parenting a null layer to the camera and moving that around and keframing it, and the third one is using the 'C' keyboard shortcut and keframing it, i think the thrid and the first options are the same with the noteworthy point of the thrid one being considerably user freindly to use.


GREAT TIPS	

when i talk about blur deapth maps this is what i mean, so let me first explain 2 types of blur maps. one is the one where you generate using phtoshop filter or the after effects one from the addon and the 2nd one i'm talkinng about just a manualy created gradient black and white solid. with black in the middle and gradiating out to black. both these types of blur maps are essentially the same because they create a layer with black annd white colors and on a realisitic deapth blur map, the black and white values are transparent depending on the deapth of the scene as opposed to the gradient one which is not based on the true deapth of the scene. and this deapth map is used for several effects, some of which are displacement map, camera lens blur., whith displacement map you might need to use fast box blur.  by defualt white value is blurred and black value is not blured but you could very easily invert it under the camera lens property, or just invert the deapth map blur using the invert effect. 

Mapal - How To Animate Like Dodford (After Effects Tutorial) just watch this a few billion times, this is all you need to know to animate increadble looking videos, this is actually fucking amaizing.
Some tips from the video above- For talking about an idea and introducing the audience to it start by showing it on an old crt tv, mask out the screen and then have the screen alone on a dublicated layer and set it's blending mode to one of the avaialble ones and then reduce opacity and play around with the proper settings. 
this next tip is to blow out the highlights and overlawy them on the existing layer - to the tv image without the screen- dublicate it and on the dublicated layer, use the extract effect to take out the blacks and you can individually move the top selectable vertex points to feather the removal of blacks, and then use the curves effect to play arond with the highlights and then add the glow effect to it to make the highlights glow, note that if you use deepglow, it has a built in chromatic abberation option in the effects panal check that. and then add a posterizetime 12 fps and wiggle 15,.5 to the exposure of the deepglow, then overlay it on the normal tv footage below the tv glass screen overlay. can also add tint to change it's color
zoom a little into the tv as the footage is playing on it.  so after the first scene has played on the tv, you can cut to the same scene on a full screen without the tv this time, obviously you're going to apply a few effects to it to make it look increadble.  and then to swtich to a diffrent scene of the same topic, you can match cut it by zooming, eg - scene 2 to scene 3, keyframe the starting scale at regular scale/100% then move formaward beyond the point where layer ends and on to the scene 3's point where the zooming sshould stop, and drop a keyframe on the scale with it being 120% scaled up, Now go back to the first key frame on secene 2's scale property, but now select scene 3's scale property (yes, before the scene 3 layer even starts) and drop a keyframe of 100% scale on the scene 3's scale property, now make sure the key frames on both the layers are overlapping and alighned to be at the same time, now do the same with the end keyframes, go on to the scale property of the scence 3' and drop a keyframe with 120% zoomed in and alighn it with the end keyframe of the scene 2's scale keyframe, have them over lap, so in summary, both starting keyframes and end keyframes over lap with one another among scene 2 and 3, this is inspite of the fact that the scene 2's end keyframes are beyond the end point of the layer and scene 3's starting keyframes are before the inpoint of the layer. and they go from 100 to 120 percentage scaled up and easy ease it to give it a smooth match cut and also turn on motion blur. 
adding flicker- the following expression to the opacity of the adjustment layer on the whole comp- posterizeTime(12); and then wiggle (10,50), this will make the opacity expression only render every 12 frames, and will send will give the whole footage a misterious look.  
adding camera shake,First zoom in a little like 103% to mitigate any black edge pixels. this is to be done on a new adjustment layer's postion property. - add posterizeTime(12); and then wiggle (222,2) this will  give it a slight movement that will only render every 12 frames aka half of 24 fps
add a hue and saturation effect individually to each layer and to match the contrast and make them black and white or slightly colored depeindng on your peference. 
then add a vigeneette to the whole scene but make it subtle. 
then on the whole footage add another adjustment layer and add two effects to it, first one being chromatic abberation - play around with frame layout options, and the second one being optics compensation - reverse the lens distortion to it
Now, for creating  depth map layer for camera lens blur, you need to create a new black solid and then create an ovel shaped mask on it and then the outside of the mask will become trasparent, so to make the out side of the mask white- drop a Solid composite effect to it and set the color to white. the solid composite will fill the trasnparent chanel with the color solid compositie is set to black. then add a new adjustment layer and slap camera lens blur effect on to it and selelct the newly cready deapth map solid as the blur map for the effect in the adjustment layer and also select masks and effects, you can then move around the mask path to blur out the parts you want blured and then also, crank up the blur to a preffered point. this also looks great on text/article. it looks espically good with chromatic abberation and optics compensiation reversed. 

Okay now this is the secret sauce for how to make certain videos look prossional and cool. this following technique makes it mysterious and great looking, so do the following. let me first explain what the effect is and then break down how to do it, so it's essentialy parts of the footage slightly bluring out randomely and then moving on to a diffrent part of the screen and bluring that out (continniously moviing across the screen and bluring out anything that come's in it's way), so it's basically a turbulant displaced black/white circles (deapth map blur layer) with it's path animated and evolution animated too, and its moving around the screen and acting as a depth map blur for camera lens blur on another adjustment layer. READ THIS > so this is how you do it, create a cricle then add a turbulent displace and crank that up like your life depended on it, then add evolution time to it but not too much maybe time*10; , then ADD FAST BOX BLUR, to smooth out the edges of the animating blobby circle, then add solid composite effect to it to make the transparent parts of the solid white, then create a new adjustment layer and add the camera lens blur effect to it then select the newly creadted deapth blur map to it's blur map layer property and selct masks and effects.
so this is a better way to do the above part, this whole blurring out of certain parts of a video should be done by using either turbulant noise or fractor noise, this comes with black and white spots on the scren by default crank up the contrast or even lower it then animate the noise, then use this as the deapth map instead of the methond above.  
Add grain to the whole footage on a solid layer and set it as overlay. blending mmode or something. then add another solid and add fractol noise. increase the contrast a whole bunch and lower the brightness to essentialy create dust and scrateches and increase the complexity and decrease the size of it adn then evolution it with expression,posterize time 6 fps , and  random(20000)> then blending mode to add. then dublicate this solid and invert it to also add black scrathes, this method will give you both white and black scratches, add the sutiable blending mode 
then drop a pixilated/crt overlay on everthing, and set the blending mode.


You can give any layer the following effects by right clicking on a layer and selcing 'Layer Styles'- with 'Stroke' being the most useful of them all with a lot of use cases particually on layers with transparent portions. You can also apply one of these to a null and copy with property link and mass apply it on to as many lasyers as you want. 
Drop shadow
Inner Shadow
Outer Glow
Inner Glow
Bevel and Emboss
Satin
Color Overlay
Gradi ent Overlay
Stroke

FX console on top of searing for effects and stuff within ae can also be used to copy the current frame on which the play head is to clipboard and then paste it into photshop or where ever., or can even directly export as png. 

Pay close attention!! if you dont want an applied effect to be shown on a certain area of the footage to which it's applied you can mask it out BUT the following option is not availabe in the effects panal under the effect and can only be found in the timeline panal under the effect > search for Compositing Options in the timeline panal, this WILL NOT show up in the effects panal for some weired reason, maybe in future updates it will but as of 2024 july it doesn't. then add the plus icon and add the mask, if you want the mask inverted, go to the actual mask and add or subsrtract it depending on what you want. and you'll have the desired effect. and yes mask needs to be enabled, if the mask is set to none it  wont work. 

to create a miniture effect where things seem tiny even it's just a regular footage, so first apply the camera lens blur on the footage and then create a new solid layer to create a deapth map for camera lens blur's Blur map source layer. so on the new solid set the fill to liniar gradient, and then have one side be black and the other be white, white will be out of focus and black in focus, so in order to create a minituer effect you want for things out of focus to be high and the area of focus to be very narrow, so adjust the black and white gradient accoridgly and then when done, go over to the orginal layer's effects panal and link the blur map to the solid gradient layer using camera lens blur's drop down deapth map property, also if you're using the linear gradient effect instead of the native liniear fill option on the solid layer, in the camera lens blur effect on the footage layer's camera lens option's deapth map propetery's option- select effects and masks for it to work. , after all is done and linked, you can mess with blur focus distance to dynamically chosose what stays in focus and what's blurry. and also mess around with the blur radious to increase/decrease the intenceity of the blur. to sell the effect even more, add a viberance effect to it and crank it up to make it appear as thought it was a miniutre set created in a studuio or soemthing this is to make it look unnatureal and give it the semblense of realism of miniture footage., now if the footage you're working with is a little compmlicated where a single linear gradient can't be applied, just create multiple solids and add the linear gradient to them according to how far and close they are individually, eg, if there's roads, buildings, you can just do them individually for left buildigns first, then on the right buildings, and then on the road and then pre comp them and use them as the blur map for the camrera lens blur.

add the wiggle expression to glow, to make it look interesting. 

Creatig a pre comp, two options - Leave all attributes in the current comp or Move all attributes into the new comp, Okay this is not always consitant so double check this everytime but it's increadbly improtant for when the footage you're working with is a large resolution footage, or the footage has been scaled up to be out of the borders of the current comp, 
Leave all attributes in the current comp does serveral things, 
	1. if you have any effects or masks applied to the layer, they will be left in the current comp on the newly created comp layer but this only happnes when only one layer is being precomped, other wise the option to leave all attributes in the current comp is grayed out. 
	2. when there's only one layer being pre comped, if the resolution of the layer is beyond the res of the current comp, the pre comp will create a comp corrospoinding to the original res of the layer being precomped and it wont down scale it. 
	3. If you are only precompling one layer and if the layer is scaled up  in the current comp, it'll retain the edges that are out side of the current frame in the current comp, and it wont trimp out the edges. so essentially the whole layer in it's orignal state will be precomped, retaining all it's properties, resolution, aspecte ratio. 
	4. PS. this option is greyed out for Shape layer.
	

Move all attributes into the new comp does the following things. 
	1. All effects and masks will be moved into the new comp, and will be on the same layer being precommped, P.S if you're pre comping multiple layers, you will only have the option to move all attributes into the new comp for obvious reasons, which are , if there are multiple layers and they have effects and masks applied to them, when pre compling it'll only create one comp for all the layers within it so it can't place all the masks and effects of all those layers to just the precomp and that's why it moves all effects along with the layers in to the new comp on the actual layers. 
	2. If the layer that's going to be pre compled has it's resolution beyond the resolution of the current comp, the new pre comp will downscale the resolution to the current comp and will downscale the layer. 
	3. if the layer has been scaled up to a point of it's edges being pushed out of frame in the current comp, the pre comp will trimp the outer edges out and will also inheret the resolution size of the current comp and will disregard the native resolution of the layer being precomped. 
	4. If multiple layers are being precomped, and will have there native resolutions flattned across the board to match the res of the current comp. So it'll make each of the individual layers lose quality.


This is a great fucking tip to Make blobs, or to even make something shaprer that is blurry, place an adjustment layer over the objects/layers you want to effect and then add two effects on it, one is gausian blur, and unckeck repeat edge pixels, and also add Levels(individual curves) effect in just that order. and then crank up the gausian to arond 30 or above, and then drop down the 'Channel'menu under the Levels effect and select 'Alpha' then you'll find two level adujsters below, one is above that looks like a full graph and the other is a narrower graph, Use the one above that looks like a grapth (the bigger one) this will have three points on the graph one on the left, one on the right and one in the middle, ususally you don't have to touch the middle one but just the two on each sides, bring both the left and the right side points to the middle untill you see the desired result in the comp preview window.  alternatively you could also use simple chocker instead of individual curves but simple chocker effect only works on layers with transparency 

many effects are repetitive in the way they work, what i mean is that if an effect does the same thing after every few frames, find the pefect looping point and loop it out instead of having the cpu/gpu crunch through the entire timeline of the comp. To find the perfect looping point, you need to see if the first and the currently assumed frame overlap perfectly, you can check this by hitting the camera symbol under the comp preview panal and it'll take a screenshot of the frame you're on, then move on the the frame you think matchs the first frame to every pixel, ALT click the eye symbol right next to the camera symbol on the bottom of the preview panal. or just click it without ALT to see if you see a discrepency, move a few frames back and fourth until  you find the sweet spot, if you find a frame that pefectaly matches it, then go back one frame and set that as the end point of the layer because if the first and the last frame are identical you'll end up with two same frames and that will look kinda off when playiing normally so the last frame will act as a repetead frame, to mitigate that, you need to go back a frame to make it loop seemelesly. and then time remmape and then loop it out. 

You can stack the same effects on top of one another to give it an interesting look. this is useful for many times. so make a habbit of experimenting with it.

you can create masks on an entire layer by selecting the shape sympol on the toolbar, then making sure to select the checkerboard with a hole in it,  it's next to the star symbol( shape tool) in the tool bar on the top. and then you can double click the rectangle symbol and then double click the edge of the mask to change it's dimentions. 

Instead of using the circle shape to draw circles, use the rectangle shape, use the roundness property to turn it into a circle,  that way you can increase the width and heighth of the ball and have more options. 

you could either use motion blur on moving objects/ shapes, or use the echo effect to give it another look similar to motion blur

Convert shape path into motion path - Let's say you draw a path/shape with the pen tool in the compt prevew panal, and then you want another object/shape in the timeline to follow that pen drawn path> drop down to the path property of the drawn path, (might need to convert to bezier path in some instances by right clicking on the path>Convert to bezier path) then either just select the path property and CRTL C (copy) or drop a keyframe on the path property of the hand drawn layer/or a shape. then copy that keyframe and paste it on the the POSITION property of the object/shape's. sometimes the path is misalighen when the object moves, so make sure the anchor point of both layers is centerd before doing all this and also the playhead is at the beggining. 

this is worth understaing how to achieve, to generate fill an area in a moving video to hide a certain object/watermark/person. so the way to achieve by two ways. which at there core are the same, just diffrent ways of going about doing it, so here is what you need to do, either create a mask on a video layer and manually animate(keyframe) it's path if the object is moving. READ!!! alternatively you could do the following to automate the path tracking, place the playhead at the starting position, or the first frame you want to animate from (drop a marker to not mess up the starting point if it's in the midddle of the footage and not the begginging). trackign it and pickwipping/parrenting the path property of the mask to the tracked keyframes property DOES NOT work because path property doesn't take in x,y values, so here is what you need to do; draw a seperate shape on a new layer, make sure the shape is the size of the object you want to mask and then go to the target footage layer and track matte it to the newly drawn shape layer to punch a hole through it and reveal the background/transparncy (essentially masking the object of intrest to be eliminated). then with the target layer selected, double click on the preview panal to open it's layer panal to track it's positon and scale. create a new null layer. and select 'Edit target' under trackig to select the null layer and after tracking it all, apply it, then pickwhip the shape layer's (the one being used as a matte) postion and scale to the null layer, or just pickwhip the scale or just the postion. depending on the type of movement in the footage. then go to the tool bar at the top > window > Content-Aware Fill and you should see the transparent area on the screen which will be generative filled automatically, make sure to hide layers that might be underneeth the target layer that could be filling in the punch hole and preventing showing trasnparancy. then WITHOUT any layer selected hit generate fill layer. btw increase the alpha expanding on Content-Aware Fill by a tad bit and then preeed with generating. 

if you want to reverse the order of layers in the timeline panal, select the layers in sequance you want them to be eg, hold down CRTL and then copy the 5th layer then the 4th, then the 3rd, then the 2... and then cut them> them CRTL V paste them. you can also select the last layer and then shift click the first layer> cut and paste them > the last layer will now be the first layer. 
 
To reopen a closed shape path/ mask path, select the first vertex point and the last vertext point > right click >mask and shape path> uncheck 'Closed'. 

to get back handles on  vertex points on a shape path or mask path > right click on any vertex point> mask and shape path> uncheck 'RotoBezier'. 

to see how an effect is impacting and manipulating the footage:- create a solid layer then add the grid effect to it then add the desired effect to see how that grid is effected, eg chromatic abboration. to see which parts of the grid are effected. 	

to select the children layers, right click a parent layer> select children. 

to reset multiple properties at once, select the all the properties on how many ever layers you want, while they are selectd, double click the move tool in the tool bar to reset scale and positon, and double click the rotation tool to reset rotation. position reset doesnt work on hand drawn shape but scale reset and rotation works on shape layers too.  


ALWAYS color lablel layers when you have too many or even a few layers make a habbit out of it. 

for glowing edges > Find edges > levels > glow/deepglow X 2 > 4 color gradient set to soft light under the effecs' properties. and then precomp it and overlay it on the orginal footage.

to reverse keyframes, select keyframes, RMB on any selected keyframe > Keyframe assistannt> Time-Reverse Keyframes. 

can quickly increase or decrease the exposure of the entire comp in the comp preview window's bottom options. the symbol looks liek a flower or a camera's lens's closing cover, it has number to it's right. this is just for vieweing/previeing puposes, it doesn't render when exporting the project. 

you can toggle between diffrent viewing modes such as 
RGB
Red
Green
Blue
Alpha
RGB Straight
all from undeer the preview compt preview panal, the default symbol for it is red green and blue balls placed along side one another forming a triangle. the symble changes depending on which option is selected. you can quickly ALT click it to toggle between rgb and alpha channels. 

You can quickly show if a layer has any masks or not by toggling the 'Toggle mask and Shape Path Visibility' (symbol is a rectangle with one top left corner cut out), it's located in the comp preivew panal at the bottom among other tiny many options. Another botton next to it is the 'toggle transparancy grid' which will alow you to show the transpirancy if any of the entire timeline layers. 

This is such a great fucking feature!!!= REgion of interest botton in the comp preview panal, at the bottom, which will allow you to draw a region of intrest rectagnle, it will only render the area you select to quickly see what an area looks like as ooposed to rending the whole thing in lower resolution, i 've tested it and it indeed only render the part of the screen you draw the regioun of interst on, it's great on the cpu when the effects are too resourse intensive , you can also trim comp to region of intrest and make a comp smaller without puttin in the exact numbers for resoluion, you can also lower the comp preview resolution at the bottom of the panal tempereraly to make the timeline grind through the timeline faster to test how something looks on one part of the screen. 

Preview panal- enable it from windows if not visible= best for working smoothly in ae when working with resource intensive footage and layers. enable skip frames and lower resolution, don't chagne the frame rate, that doesn't work as well. (there's a bug where it might not show all options so toggle it off and of from the windows menu)

each layer'e visibility Eye symbol changes in a minor way when any blending mode is turned on like- dissolve/darken/multiply/screen.....

always tooggle motion blur Symbol in the timeline pannel for clean moving animations. 

The concept of spaces in AE:- spaces is where the layer starts and ends from, it's the total area of the targeted layer. 
Layer space- if you apply an effect to a layer that is not a vector layer/ or a layer that is not being continualy rastorized, the 0,0 positioning of the layer would be the top left of the LAYER and not the comp. eg you have a 1920x1080 comp but you have a footage/layer that is only 720p and it's not being scaled up, but is in proportion to the size against the backdrop of of a 1080 comp, an applied effect such as gradiant ramp, would calculate the starting 0,0 positioning of the effect to the top left corner of the layer as opposed to the top left corner of the comp. 
Comp Space - this is taking into account the area of the entier comp, in some instances when you apply an effect to a layer, an effect such as gradian ramp, say you apply it to a vector layer, it'll calculate according to the comp space, ie it's starting position will be that of the top left corner of the entier comp which is that it's possition will be 0,0 at top left corner of the comp. 
You can change how spaces work on layers while effects aare applied to it by using the 'toComp()' expression. 

You can convert a layer into a guide layer by RMB > Guide layer , it wont show when rendering the footage but it'll show while editing it in AE. 

You can turn any layer into an adjustment layer by toggling the (Circle with half circuled filled), (it's in between the 3d symbol and Motion blur symbol on the timeline)

every shape layer has a star symbol before it's name in the timeline panal. 

when using a layer as a matte for another layer especially texture layers as matte or even using one of the blending modes on a texuture/anyother thing for other layer/s. on the layer that is being blended or track matteed, apply the curves effect and crank up the contrast for the desired look and feel. 

monochrome/monochromatic means black and white.

adding diffrent visual effects to strokes is so easy and it's all built in already, no extra effect is needed, when you draw a stroke using the pen tool, just twerl down to 'Wave' and change things around there, also mess around with tapper, change the butt cap/ round cap. so many things to customize under it, you can also add diffrent color gradient to it by doing the following, add trim paths copy the stroke make the stroke bigger and now use the matte layer on the apha channel, then add a diffrent color to it then add fast box blur followed by glow. to give it that extra look.

Okay this is a great tip= to stagger layers by prefered number of frames, which means you want to start each layer by being delayed by a certain amount of time/frames. you'd need to select all layers and then go to the start of the timeline while all the layers are selected then move the playhead forward by the desired amount of time/ frames you want for each layer to be delayed by, then while all layers are still selected, hold down right-ALT + ] to tempereraly trim off the layers to the right of the playhead. then right click on any of the selected layers (every layer selected), then select 'keyframe assistant'> 'sequence layers' and then select Okay, (DON'T check overlap) 

Lets say i wanted to create a graph and wanted to put down markers for each year/or any data on the timeline at the bottom or on the left side (horizontolly or vertically) what i mean is, let's take the example of an L shaped graph, on the left side is money spent and on the bottom is timeline of years. so for each year, i would want them spaced out perfectely like 2010, 2012, 2014.... so instead of eyeballing it and manually spacing it out, there's an increadbly easy way to do it by putting down the first year and the last year's marker on the line then dublicate the first marker the desired number of times depending on how many years you want to show, then while all the dublicated markers are still overlapping, select all the markers, including the last marker, first marker and all the overlapping markers, then go over to the align pannel and then space them out horizontolly or vertically depending on which side of the bar it is on. Btw Align works wonders. 

to make a great background do this. Fractal Noise(contrast 500, scale 250(type it in when you click away it automacialy turns to 482 sometimes.) evolution to time*50) > Fast Box Blur > Posterize > Find Edges > Extract > simple chocker > fill/4 color graident. 

good extra objects creater - use the grid effect on a solid > use cc sphere on it. 

use echo to dublicate items/texts or any vector - make sure that the precomped layer is tightly fit aruond the vector layer/text and then add echo to it or motion tile. 

use the efffect 'Median' to turn the layer/footage into a cartoonish layer/ it's a great effect for a specific style. 

brush strokes also gives the layer a s specific style. it's kinda turns the layer/footage into brush drawn. 

Dont forget to toggle continusasly rastorize (the sun like/star like) symbol next to shy layer symbol on the layers's timeline pannel. 

to reverse the order of the layers iin the timeline, selcet the layer you want as the layer onthe top/first layer. and then sequenceeally select the rest of the layes in order of prefference than cut (CRTL X) then paste them again (CRTL V)

(this tip is only true in some specific case but still good to remember. )to chnage the shape of any shape layer that was drawn in ae or illustrator, or photoshop (vector shapes), you'll see the points on each corner of the shape but you wont be able to move that point indipendent of the whole shape, so to be able to manipulate each point individually, drop down to the 'Path' property of the vector/shape layer, then right click and selct 'covert to bezier path' then switch to the pen tool by pressing G, then while the layer is selected, you can click on a point and move it independentlly, sometimes you need to go back and forth between the men tool and the Move tool (V) to select just one point, so when switching to the move tool, LMB anywhere on the comp preview screen outside of the layer. and then select the point again, then switch to the pen tool (G) then proceed with changing the shape of the layer.  

add glow to just the highlights/ shadows, use the extract effect then removew what you want to remove > add deepglow/glow w/ wo/ chromatc apbboration checked on deepglow. then have this layer duplicated undeteeth it and remove the extract and glow effects from it. you can also add the wiggle expression the glow expression, also turbulant displace, and so many other things, even cc composition to pile up on the effect and give it a diffrent look. so many creative thigns can be done using just this and it always looks great. 

Turn turn one shape into another on the same layer and seemlessely and also ditervmine what position it's going to be at when it transforms into the 2nd shape. so here's how to go about doing it. Let's say you have a squire that you want to transfrom into a circle. First with The 'Q' key hit, cycle through the shapes until you have a squire, then hold down shift > Lmb on the preview comp and drag drop until you haeve a perfect squire. Now this is key, you want the shape you've drawn to be a bezier shape, there's two ways you can do that, one is to check the 'Bezier Path' checkbox at the top in the toolbar BEFORE you draw the squire, this way it'll be a bezier shape right from the get go. the second method is turning an already drawn shape into a bezier layer. this is done by selecting the squire layer in the timeline panal, then hitting CRTL F and searchign for 'Path', it'll list the rectangle path or what ever xx path, RMB on the path property and then select 'convert to bezier path' this will convert it to bezier path. It'll change the xx path property to just 'Path' property, unswirl/unravel the property until you see the path property that is keyframable. Now before you drop a keyframe, make sure the squire is at the desired postion and desired size. then. drop a keyframe. 
Now draw another shape eg circle and make sure it's a bezier shape, then go to it's path and before dropping a keyframe make sure it's at the desizred size/position, then drop a keyframe on it. now copy the keyframe from the circle's path and paste it on the path property of the squire at the time you want for the transfrormation to have completed. after it's pasted. it'll automatically/ magically intropolate the tranformation between the two path keyframes on the squire property. you can procedd with deleting the cicle layer. Just an FYI if you want to change the entier shape to a diffrent shape withotu it transforming or anything, you just want it to instantely change it's shape, say you want a squire to be a circle but not really animate or transfrom into one, you could do the following, go down to the path property of the circle layer and selct it but dont' drop a keyframe, and then go to the squire property's path and select it then paste on it CRTL V, it'll change it's shape instantly to a cicle. IMPORTANT thing to note is that sometimes the intropolation between the two shapes is weired and unintunitive and looks off, to fix that, select one vertex point on the first shape > rmb > 	mask and shape path > set first vertex. for the second shape, do the same but make sure to set the first vertext point closet to the first vertext opint on the first shape. 

Ae is not a design software it's a motion graphics software, so use illustrator to draw shapes and desighns and then select all in illustrator then move over to ae and have the pen tool selected 'G' and CRTL V to paste from illustratior. 

when animating trim paths there is an icon to quickly switch between clock wise animation or anti clockwise animation. it's called reverse path direction when you hover over it, it's two lines running parallel to each other in horizonntal positon, it's right next to the xx path property. eg polyster path property. 	

you can add an adjustment layer and add a transform proerpty to it to move every shape underneeth it, or you could add the wiggle expression to the positon property of the tranform property of on the adjustment layer. then precomp the layers along with the adjustment layer you want affected. .

If you want to make a line of text travel along a path like a circle, like you want the text to travel on the inside of the circle along the circle line, select the text layer and create a mask on it, the mask will act as a path for the text to travel along. after it's done create an animator for it using the inbuilt drop down menu under the text layer and select the position animaotr and one the properties for the position animator animate either the x or the y property and it'll travel. 

If you want the spacing of a text line to happen from the middle instead from the left so the text spaces out from the middle ( center the anchor point before toggling the animate the tracking property) 







PHOTOSHOP TIPS FOR AE
You can use psd files from photoshop into after effects, import them as composition, when you have multiple layers, you can change the text/ or positon of one or more layers in photoshop and it'll automatcially update it's new location/ or newly updated text even with a new font if you changed it, all on the fly, in real time in ae. 

if you want to change the text in ae after having imported the psd file from photoshop, you can change its text by RMB on the text layer > create > convert to editable text. and you'll be able to change the text right from whitin ae. 


PREMIRE PRO TIPS
this is the only premire pro tip in the whole thing but there's an increadble way to make jump cuts looks seemless when talking using the morph cut effect in Pro. note that the duration of the transition should be 4 frames, i've tested it and it works great for jump cuts of a person talking. 

WHILE exporting you'll have 3 options= 
if you have a 30 fps video and exoprting at 60 fps this is how it'll effect it. 
frame sampling- will dublicate the frames in between frames - no diffrence in appearance at all. 
frame blending- will add a kinda of like a cross fade effect inbetween frames. looks ghosty. 
optical flow - will generate new frames in between and looks increadble!! 



AE Effects to know about:- (read them and guess what each of them does and confirm your answer from the notes above.)
Effects of Ae. 

3D CHANNEL
3D Channel Extract
Depth Matte

AUDIO
Backwards - reverses the audio
Bass & Treble 
Delay - makes audio delay, like echo audio!  
High-Low Pass
Modulator
Parametric EQ
Reverb

BLUR & SHARPEN
Camera Lens Blur - most sophisticated blur effect with ability to use depth maps
CC Radial Blur - great for focusing only on one area of the screen. it can make everything else zoomed in while keeping the subject in focus and default zoomed. has so many applications. zoom ability is not default under properties of the effect so you have to select it. 
CC Radial Fast Blur
Channel Blur
Directional Blur
Fast Box Blur
Gaussian Blur
Radial Blur - old version of CC radial blur/ don't use this. 
Sharpen
Smart Blur - this doesn't apply the blur uniform across the whole image but instead blurs the image based on its contrast ie it only blurs out similar looking tones while maintaining edges, it maintains the overall sharpness of thh image while smoothining out areas with less contrast.
Unsharp Mask

BORIS FX MOCHA
Mocha AE
Mocha Pro

CHANNEL
Blend - this blends two layrers.(you gotta select the other layer in the properties of the effect)
CC Composite - this is an effect for the blending modes from the timeline but in an effect and is much more useful than the blening mode available in the timeline on each layer. 
Channel Combiner  
Invert
Minimax
Set Channels - can take diffrent channels from other source layers. ie R/g/g and overlay it on the layer to which the effect is dropped.
Set Matte - works similar to the matte option on the layer in the timeline panal. but is much better with more benifits.
Shift Channels - shifts channels r/g/b aka can also be used to crete chromatic abboratin by dublicating the target layer 3 times and dropping the effect on all of them, then turning off everychannel but one for each of them. RGB. then slightly shifting it's postion r to the left, g as is, and b to the right. 
Solid Composite - fills up the transparent areas of the layer with user defined color, defualt is white.

COLOR CORRECTION
Auto Color
Auto Contrast
Auto Levels
Black White
Brightness & Contrast
CC Color Neutralizer
CC Color Offset
CC Toner
Change Color
Change to Color
Channel Mixer
Color Balance
Color Balance (HLS)
Color Link
Color Stabilizer
Colorama
Curves
Equalize
Exposure
Gamma/Pedestal/Gain
Hue/Saturation
Leave Color
Levels
Levels (Individual Controls)
Lumetri Color
Photo Filter
Shadow/Highlight
Tint
Tritone
Vibrance

DISTORT
Bezier Warp - allows you to manipulate/warp/distort the shape/size of the layer using Bezier handles. you can pull and tug the handles to warp/ distort the image to your liking
Bulge - magnifies the area of the layer inside the radius of the unrendered circle/bounding box on the layer. makes a fish eye magnifying effect on the layer. pretty cool.
CC Bend It - points based deformation, it bends based on point a and point b . this is simeler and will get the job done most times. this has several styles of bending but they are diffrent than the onces available for cc bender.
CC Bender - box based deformation. it bends based on the bounding box, this has more features. and is unnatural looking unless tweaked, it offers diffrent styles of bending. 
CC Blobbylize - this makes the layer look liquidy, it could be used for so many artistic signitures. 
CC Flo Motion - this effect is farirly uselss, it has two points that can be placed anywhere on the preview layer and then it'll distort those points, it'll just create a black hole like warp around each of the points, you can keyframe the points to animate them. 
CC Griddler
CC Lens - i Love this, It can create an optics compensation like effect where, while also doing much more.
CC Page Turn 
CC Power Pin - very useful to distort the layer based on 4 points, one on each corner of the frame. can be used even on circles. 
CC Ripple Pulse - this is a strange effect because it only works when keyframed, it doesn't do shit by defualt when droped on a layer. the properties have to be keyframed. pluse level property and then amplitude. 
cc Slant - slants the layer. 
CC Smear - uses two masks to smear from one point to another
cc split - create a split between two points, like the opening of the mouth. 
CC split 2 - does exactly as split one with one extra feature, ie lets you control the shape of the curve of both the upper lip and the bottom lip independently. 
CC Tiler - this is an insanly good and useful effect, let's you create copies of the layer and adds them to each side of the layer in the preview comp, when you zoom out, they are all stacked next to one another in the formation of tiles. It's great for depicting an infinate universe theory/ many more applications. 
Corner Pin - old and obselete just use cc power pin
Detail-preserving Upscale - does a better job of keeping in details in a layer when scaling up. say you had a 1080p comp and a footage of 480p, do not scale up the footage but instead drop this effect on the layer and under properties select either set to comp withdh/height or use the scale slider on the properites of the effect. slightly reseroce intensive but worth it. 
Displacement Map -allows you to distort a layer by shifting its pixels based on the color or luminance values of another layer, called the displacement map. The effect displaces pixels horizontally and/or vertically, creating warping or ripple-like distortions influenced by the variations in the map layer. 
Liquify - warps, meshes the footage. 
Magnify - magnifies a user defined area of teh layer. 
Mesh Warp - much like Bezier Warp but very detialed, it creates a grid that whose intersections you can move around to manipulate and distort the layer.  mesh warp and bezier warp have seperate applications because bezier warp works only around the edges and allows you disotrt a whole lot with just one tug and pull while mesh warp is more detaild and narrowly foccused on each part of the layer. 
Mirror-
Offset - works great to have a layer repeat itself and cycle in and out of the preview window. 
Optics Compensation - zooms in and out of the layer in an interesting way, it's kinda liek fish eye lens. 
Polar Coordinates - 
Reshape - this is a great effect to morph one object into another, detailed explinaion above. 
Ripple - creates this rippel like effect, does it uniformly on the entire layer if you crank up the value to 100. might be useful for artistic purposes. it's kinda like water ripples on in the pool while raining. 
Smear - fairly stright forward smearing effect between two points. 
Spherize - magnifies a user defined portion of the screen it's NOT cc Sphere, that does something else ie it turns the layer into a globe like 3d but it's actually 2d. 
Transform - better way to use transform options and this works even the native transform of a layer doesn't work for some specific resaons. 
Turbulent Displace - creates a wobbly/ liquidy effect. 
Twirl -
Warp - does a lot of interesting warps, arc, bulge, flag wave, fisheye, and more. 
Warp Stabilizer - stabalizes the footage. 
Wave Warp - ripple/flag like wavvy effect. 

EXPRESSION CONTROL
3D Point Control
Angle Control
Checkbox Control
Color Control
Dropdown Menu Control
Layer Control
Point Control
Slider Control

GENERATE
4-Color Gradient
Advanced Lightning
Audio Spectrum
Audio Waveform
Beam
CC Glue Gun
CC Light Burst 2.5
CC Light Rays
CC Light Sweep
CC Threads
Cell Pattern
Checkerboard
Circle
Ellipse
Eyedropper Fill
Fill
Fractal - increadbly interesting, creates lsd fractols, kaleidoscope, and much more. 
Gradient Ramp
Grid
Lens Flare
Paint Bucket
Radio Waves
Scribble
Stroke
Vegas
Write-on

IRREALIX
looPFlow

KEYING
Advanced Spill Suppressor
CC Simple Wire Removal
Color Difference Key
Color Range
Difference Matte
Extract
Inner/Outer Key
Key Cleaner
Keylight (1.2)
Linear Color Key

MATTE
Matte Choker
Refine Hard Matte
Refine Soft Matte
Simple Choker

NOISE & GRAIN
Add Grain
Dust & Scratches
Fractal Noise - Slower but with repeating and cycling the effect for a seemless loop. 
Match Grain
Median
Median (Legacy)
Noise
Noise Alpha
Noise HLS
Noise HLS Auto
Remove Grain
Turbulent Noise - faster but without repeating and cycling the effect for a seemless loop. 

OBSOLETE
Basic 3D
Basic Text
Color Key
Gaussian Blur (Legacy)
Lightning
Luma Key
mocha shape
Path Text
Reduce Interlace Flicker
Spill Suppressor

PRESPECTIVE
3D Camera Tracker
3D Glasses
Bevel Alpha
Bevel Edges
cc Cylinder
CC Environment
CC Sphere
cc Spotlight
Drop Shadow
Radial Shadow

PLUGIN EVERYTHING
Deep Glow 2

ProductionCrate
Crate's Godrays

SIMULATION
Card Dance
Caustics
CC Ball Action - THIS IS SO FUCKING GOOD! ESPECIALLY SCATTER PROPERTY.
CC Bubbles
CC Drizzle
cc Hair
CC Mr. Mercury
CC Particle Systems II
CC Particle World
CC Pixel Polly
CC Rainfall
CC Scatterize
CC Snowfall
CC Star Burst
Foam
Particle Playground
Shatter
Wave World

STYLIZE
Brush Strokes
Cartoon
CC Block Load
CC Burn Film
CC Glass
CC HexTile - creates a kaleidoscope like effect.
CC Kaleida
CC Mr. Smoothie
cc Plastic
CC RepeTile
CC Threshold
CC Threshold RGB
CC Vignette
Color Emboss
Emboss
Find Edges
Glow
Mosaic
Motion Tile
Posterize
Roughen Edges
Scatter
Strobe Light
Texturize
Threshold

TEXT
Numbers
Timecode

TIME
CC Force Motion Blur
CCWide Time
Echo
Pixel Motion Blur
Posterize Time
Time Difference
Time Displacement
Timewarp

TRANSITION
Block Dissolve
Card Wipe
CC Glass Wipe
CC Grid Wipe
CC Image Wipe
CC Jaws
CC Light Wipe
CC Line Sweep
CC Radial ScaleWipe
CC Scale Wipe
CC Twister
CC WarpoMatic
Gradient Wipe
Iris Wipe
Linear Wipe
Radial Wipe
Venetian Blinds

UTILITY
Apply Color LUT
CC Overbrights
Cineon Converter
Color Profile Converter
Grow Bounds
HDR Compander
HDR Highlight Compression

VIMAGER
ScaleUp





ae plugins to downlaod

Coco
imgPaster (ae script)
Motion 4
Overlord
fx console
loopflow
deep glow
deapth scanner
true comp duplicator (ae script)
