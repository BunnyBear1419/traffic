Config = {}
Config.Debug = false
Config.AdminAce = 'traffic.admin'
Config.LearnAce = 'traffic.learn'
Config.ScanInterval = 750
Config.StuckCheckInterval = 1500
Config.MaxTrafficTasks = 80
Config.RouteSampleDistance = 6.0
Config.RouteSnapDistance = 18.0
Config.ObstacleProbeDistance = 22.0
Config.RecoveryTimeout = 7000
Config.Learning = {enabled=true,minSpeed=2.0,sampleInterval=350,maxPointsPerRoute=500}
Config.DefaultMode = 'normal'
Config.Modes = {
 normal={speed=1.0,density=1.0,behavior=0},
 light={speed=1.0,density=0.55,behavior=0},
 heavy={speed=0.78,density=1.25,behavior=0},
 stop={speed=0.0,density=0.0,behavior=1},
 emergency={speed=1.35,density=0.75,behavior=2},
 race={speed=1.25,density=0.8,behavior=3}
}
Config.AppearanceGuard = {enabled=true,interval=2000,repairCooldown=5000,repairInvisible=true,maxManagedNPCs=500}
Config.AdaptiveRouting = {enabled=true,minHotspotHits=2,avoidRadius=16.0,obstacleReportCooldown=8000}
Config.ZoneTypes = {
 normal={radius=80.0},light={radius=80.0},heavy={radius=80.0},stop={radius=50.0},
 oneway={radius=60.0},closure={radius=60.0},emergency={radius=80.0},race={radius=100.0}
}
