IOS Plugin Development Test

Git Link:- https://github.com/DharmikGorsiya/Unity3DSwiftPlugin

Usage :- import plugin file “YodoTestIOSPlugin.unitypackage”

**Unity3D Side**

**Implementation**

**Initialization**
You can call ResourceUsage.Instance.Init() for initialization of plugin

**StartTracking**

You can call ResourceUsage.Instance.StartTracking() from where you want to start the tracking of the data.

**StopTracking** 

You can call ResourceUsage.Instance.StartTracking() from where you want to stop the tracking of the data and it will return a list of tracked data between start and stop with an interval of 1 second.

**Dependency** 

Newtonsoft Json for converting data for Unity Side.

**IOS Native Code**

**Implementation**

Created UnitySwift bridge and created class call GetInfo 

InGetInfo two methods are created and called starttrack and stoptrack.

Once the start method calls it will start a timer of 1 second and call method dotracking.
Dotracking method will track data of Ram, CPU and GPU and combine as one object and add to object list.

Once a user call stops it will convert data into string and pass data to Unity3D.

For get data of Ram,CPU and GPU I used stack Overflow and other blogs.

Thanks,




