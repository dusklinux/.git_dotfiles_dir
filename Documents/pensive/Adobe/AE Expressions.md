Expressions. 

do use the expression helper liberary that shows you all the availble expressons for each thing like for layers, it'll show you all the availbe. methods and so on. it's increadbly useful and alows you to see all of them even if you're not going to use them at this point. 
Expression Effects:-
Angle Control - allows you to control teh angle of or rotation. 
Checkbox Control - allows you to set up checkboxes = checkbox== 0 means it's unchecked while checkbox == 1 means it's checked. 
Color Control - allows you to set colors at diffrent points in time
Dropdown Menu Control- allows you to set up multiple options and even set them as master properteris so you can cycle through the options from outside the comp or just on the layer. after setting up the down menu, pickwihip to the effect from the expression box and then mention the drop down choises in arrays, for instance if you have a drop down menu of colors like red green blue yellow, write that in teh expression box in an array like this = [red, green, blue, yellow] this has to be in teh exact order as the drop down menu and then write next to it without a comma or a semicolen write this= [dropdownMenu -1]
Layer Control - allows you to select diffrent layers from the time line and then you can pickwhip to the effect and just type - .transform.postion.value. you don't have to pickwhip to the layer, you can just cycle through diffrent layers in teh layer control drop down and it'll dynamically change the main layer and add the .trasnform. postion.value of the layer selected. 
Point Control - 
Slider Control - alllows you to set up a slider with varying values 
if you want to hide the back of a 3d layer when it's rotated, place this in the opacity property = toCompVec([0,0,1])[2] or toCompVec([0,0,-1])[2] to do the opposite.


repeat = repeats things, can work in sourse text as this text.sourceText.repeat(3) and it'll repeat teh text 3 times.
width = the width of the comp
height = the height of the comp. 
sourceRectAtTime(time,extants).height/width/top/left = to find the size of a text layer. 
valueAtTime(time) = to get the properties of a layer at a specified time. 
Math.round = to round of the number.
Math.abs = always returns a postive number. takes away -/ negative sign. 
Math.min(value1, value2) = always picks the minumum value out of the two values.
Math.min(value1, value2) = always picks the maximum value out of the two values.
Math.ceil = to round off the number forard. 
Math.floor = to round off the number backwards. 
toLocaleString() = to place a comma on numbers automaticaly. this is used at the end of a number like Math.round(time*5000).toLocaleString();
value = to get the value of a property/ or to have the expression plus the user specified value also take into account eg = time*100 + value;
time = current time. 
index = to refer to the index of a layer. eg layer(index-1)
loopin(type = "", numKeyFrames = 0) loopout() in brackets i can write the following 4 things. "cycle" "continue" "offset" "pingpong";
posterizeTime() = to lower the frame rate
thisComp, thisProject, thisLayer
framesTotime = converts frames to time. /timeToFrames
clamp(value,min,max) = value is to be left as it is but min and max need to have a number spedified. this will constraint the values between min and max
length(point1, point2) = this will alow you to get teh length between two objects and you can display that information in the sourse text field of a text layer. (just pickwhip to the postion property, don't have to pickwhip to x or y but the whole positon.)
random(min,max) = places a random value between teh specified field, or you cna also just mention the max value and it'll automaticaly start from 1 as it's min number
linear(t, tMin, tMax, value1, value2) = Pefect for tying one property to another property, for instance if you want for the opacity of layer 1 to imapct the scale proeprty of layer 2, in the scale property's expersson text field, pickwhip to the opacity of the layer 1 and place it at the 't' place in the liner expression, and then specify the min value such as 20, and the max value such as 80. then specify the min and max roation of the layer 2, it'll auto interopelate the rest. 
marker = refers to the marker , can be invoked by layer(index/name).marker.key.value
marker.key() = refers to a certain marker.
toWorld,toComp = comp space or layer space, refers to the starting postion of each of the spaces. 
% (it's called modulas) = it reverts back to the starting point after hitting the max point. eg. Math.round(time*10 % 32)= this will always go back to 1 after hitting 32, try it in sourse text to see.
active = it's use to acertain if a layer is active or not like if it's visible or not. you can use it in if() statements. like if (["layer 1"].active == 0/1) {["layer2"].transform.opacity== 1/2 } else {0}  
enabled = similar to active, it's use to acertain if a layer is enabled or not like if it's visible or not. you can use it in if() statements. like if (["layer 1"].enabled == 0/1) {["layer2"].transform.opacity== 1/2 } else {0}  
thisLayer = to refer to the current layer.  
parent = can be used to refer to a property of the parent layer. eg. parent.transform.scale + 2;
hasParent = can be used in an if else statemetn like if (thisLayer.hasParent) {thisLayer.transform.scale = 0} else {thisLayer.Transform.Scale = 100}
outPoint = it's the outpoint of the layer aka the ending point of the layer on the timeline, not the end of the timeline but the end point of the layer on the timeline, eg the timeline could be 10 seconds long and the layer in focus could end at the 8 second mark so the outpoint of that would be 08:00, this can be used at the end with the dot notation. like thisComp.layer("circle").outPoint, or it can be used as such on the opacity property: - linear(time,inPoint,inPoint+.5,0,100); 
inPoint = it's the inpoint of the layer aka the starting point of the layer on teh time line, not the start of teh time line but the start point of the layer on teh time line, eg the timeline could be 10 seconds long and the layer in focus could start from the 3 second mark so the inpoint of that would be 03:00
lookAt(fromPoint, atPoint) = makes an arrow or any thing always point the target object, this is how it works: - pre requesits; current layer needs to be 3d and only works on the orientation property, might work on some other properties too, yet to check, anyways.  var target = thisComp.layer("ball").transform.position; lookAt(target,transform.position); after it's done, the Y Rotation has to be set to -90, other wise it doesn't work properly. 
key() =  used to get one of the three values from a keyframe or a marker - time, value, index. it's used as following. thisComp.thisLayer.transform.position.key(2). also the index for keyframes starts from 1 and not from 0, weird. ik. it's fucking java script atleast be consistant if you're going to be retarded about the numbering. fucking braindead shitheads.
nearestKey(time/value/index) = is used to get one of the three values from the nearest key to the playhead time, value, index.  used as follows. thisComp.thisLayer.transform.position.nearestKey(time).time; yes i checked time is both in brackets and out and it works like this. 
inTangents =
outTangents =


linear();
random();
wiggle();
seedRandom();
gaussRandom();
PosterizeTime();
Variables
Arrays
Expression Controls



[DOESN'T WORK IDK WHY]sampleImage(point, radius = [.5, .5], postEffect = true, t = time) = increadbly powerful to sample the image color at any locaion (it's dynamic) all you have to do is mention the point on the color propertie's expression. let's say you have a null layer and a shape that's static in one place, and another layer with so many colors like a normal image of somethnig or a video. i can have the static box change it's color to the color of the underlying color of the position of the null. the static box's color will alwasy coruspond to the underlying color on which the null is. open the fill color property on the static box, then enter the expresson there, first pick whip to the media/multi colored image/video. then pickwhip to the null's positon. then drop the sampleImage expression and in place of 'point' place null's postion variable or the whole path.  this also checks the alpha value of the layer below by adding [3] at the end of the expression like this. sampleImage(point, radius = [.5, .5], postEffect = true, t = time)[3]
