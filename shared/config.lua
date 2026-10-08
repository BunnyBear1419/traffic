Config = {}
Config.Debug = false
Config.AdminAce = 'traffic.admin'
Config.LearnAce = 'traffic.learn'
Config.Release = {enabled=true,masterEnabled=true,firstRunSetup=true,exportImport=true,diagnostics=true}
Config.PermissionAces = {control='traffic.control',events='traffic.events',jobs='traffic.jobs',vehicles='traffic.vehicles',zones='traffic.zones',routes='traffic.routes',diagnostics='traffic.diagnostics'}
Config.ScanInterval = 750
Config.StuckCheckInterval = 1500
Config.MaxTrafficTasks = 80
Config.RouteSampleDistance = 6.0
Config.RouteSnapDistance = 18.0
Config.ObstacleProbeDistance = 22.0
Config.RecoveryTimeout = 7000
Config.FeatureToggles = {traffic=true,population=true,routing=true,recovery=true,learning=true,intelligence=true,discovery=true,npcManager=true,appearance=true,performance=true,oneSync=true}
Config.Adjustor = {enabled=true,mode='auto',trafficLevel=70,npcLevel=70,minLevel=0,maxLevel=100,updateInterval=3000,lowPopulation=60,highPopulation=160,criticalPopulation=260,lowPlayerCount=8,highPlayerCount=32,minTrafficScale=0.15,maxTrafficScale=1.35,minNPCScale=0.25,maxNPCScale=1.25}
Config.Learning = {enabled=true,minSpeed=2.0,sampleInterval=350,maxPointsPerRoute=500}
Config.DefaultMode = 'normal'
Config.Modes = {normal={speed=1.0,density=1.0,behavior=0},light={speed=1.0,density=0.55,behavior=0},heavy={speed=0.78,density=1.25,behavior=0},stop={speed=0.0,density=0.0,behavior=1},emergency={speed=1.35,density=0.75,behavior=2},race={speed=1.25,density=0.8,behavior=3}}
Config.AppearanceGuard = {enabled=true,interval=2000,repairCooldown=5000,repairInvisible=true,verifyVariation=true,maxManagedNPCs=500,maxRepairAttempts=4,retryBackoff=1500}
Config.AdaptiveRouting = {enabled=true,minHotspotHits=2,avoidRadius=16.0,obstacleReportCooldown=8000,failurePenalty=3.0,congestionPenalty=1.5,confidenceBonus=2.0}
Config.RouteAvoidance = {enabled=true,minimumHits=3,radius=20.0,penalty=8.0,decayHours=24,maxEntries=250,clearOnRouteDelete=true}
Config.RouteLearning = {enabled=true,successWindow=45000,minProgressDistance=25.0,minSuccessSpeed=2.0,confidenceGain=0.75,confidenceLoss=0.5,decayHours=48,maxConfidence=100}
Config.OneSync = {enabled=true,requestControl=true,requestTimeout=300,maxControlAttempts=2,migrationGrace=1500}
Config.Intersections = {enabled=true,radius=24.0,maxQueued=6,gridlockSpeed=2.0,cooldown=5000,emergencyBypass=true}
Config.MLOIntelligence = {enabled=true,roadProbeRadius=24.0,classify=true,minimumHits=2,categories={'building_entrance','garage','tunnel','parking','dead_end','blocked_road','unknown'}}
Config.MLOCollisionAudit = {enabled=true,scanOnStart=true,scanInterval=300000,maxResources=300,maxFilesPerResource=500,maxFindings=500,includeExtensions={ybn=true,ydr=true,ytyp=true,ymap=true,ymf=true,ydd=true},minimumDuplicateSize=64,allowResourceStop=false,allowGeneratedFixes=false,ignoreResources={},runtime={enabled=true,radius=28.0,minHits=2,maxEvidence=500,mergeRadius=18.0,confidenceDecayHours=168},fix={enabled=true,requireAdmin=true,dryRun=true,backup=true,rollback=true,maxActions=5}}
Config.AutoDiscovery = {enabled=true,sampleInterval=1200,minSpeed=3.0,minSamples=8,maxCandidates=100,successWindow=45000,confidenceStart=1.0,confidenceGain=0.25,confidenceLoss=0.5}
Config.NPCManager = {enabled=true,maxSpawnPoints=100,maxManaged=250,respawn=true,respawnDelay=5000,spawnDistance=180.0,despawnDistance=260.0}
Config.Performance = {enabled=true,minScanInterval=350,maxScanInterval=2000,minTasks=25,maxTasks=100,highPopulation=160,criticalPopulation=260}
Config.ZoneTypes = {normal={radius=80.0},light={radius=80.0},heavy={radius=80.0},stop={radius=50.0},oneway={radius=60.0},closure={radius=60.0},emergency={radius=80.0},race={radius=100.0}}
Config.ZoneBehavior = {baseSpeed=22.0,lightSpeed=24.0,heavySpeed=16.0,raceSpeed=30.0,emergencySpeed=34.0,yieldSpeed=7.0,closureExitBuffer=35.0,rerouteCooldown=2500}
Config.VehiclePopulation = {emergencyVehicles=true,militaryVehicles=true,parkedVehicleLevel=70,cleanupDisabled=true,modelSuppression=true,emergencyModels={'police','police2','police3','police4','policeb','policeold1','policeold2','policet','sheriff','sheriff2','fbi','fbi2','ambulance','firetruk','riot','riot2','pbus','pranger','polmav'},militaryModels={'rhino','barracks','barracks2','barracks3','crusader','halftrack','insurgent','insurgent2','technical','technical2','technical3','apc','khanjali','chernobog','scarab','scarab2','scarab3'}}
Config.NativeSafety = {enabled=true,speedControl=true,vehicleTasks=true,shapeTests=false,populationCleanup=true,poolScanning=false,monitorScanning=false,npcManager=false,roadNodes=false,trafficThread=true,trafficCleanupThread=false,debug=false,cleanupRadius=110.0,cleanupBatch=12,cleanupInterval=250,crashIsolation=true}
Config.Framework = 'standalone'
Config.FrameworkAdapters = {enabled=false,esx=true,qbcore=true}
Config.SmartTraffic = {enabled=true,timeOfDay=true,weather=true,location=true,highway=true,nightTraffic=25,dayTraffic=70,rushHourTraffic=90,rushHourNPC=85,rushHourParked=95,lateNightNPC=20,lateNightParked=30,updateInterval=15000}
Config.SafeMode = {enabled=true,protectPlayers=true,protectMission=true,protectJobs=true,restoreOnStop=true,detectExternalChanges=true}
Config.VehicleCategories = {enabled=true,models={taxi={'taxi','taxi2','taxi3'},bus={'bus','coach','bus2'},truck={'mule','mule2','mule3','mule4','pounder','phantom','hauler'},commercial={'benson','benson2','boxville','boxville2','boxville3','boxville4','boxville5','rumpo','speedo','speedo2','speedo4'},motorcycle={'bati','bati2','akuma','daemon','double','faggio','hexer','pcj','ruffian'},sports={'adder','zentorno','t20','osiris','turismor','italigtb','italirsx'}}}
Config.ProtectedVehicles = {models={},jobModels={},allowPlayer=true,allowMission=true,allowEmergencyWhenDisabled=true}
Config.TrafficEvents = {enabled=true,maxActive=4,defaultDuration=120000,types={'roadwork','checkpoint','accident','emergency_response','fire_scene','traffic_jam','race_event','military_convoy','police_pursuit'}}
Config.JobTraffic = {enabled=true,pollInterval=3000,defaultMinimumGrade=0,rules={
 {id='police',name='Police',jobs={'police'},minimumGrade=0,priority=50,mode='emergency',trafficLevel=35,npcLevel=45,parkedVehicleLevel=35,emergencyVehicles=true,militaryVehicles=false,actions={traffic=true,npc=true,parked=true,emergency=true,military=false,events=true,zones=true}},
 {id='fib',name='FIB',jobs={'fib'},minimumGrade=0,priority=60,mode='emergency',trafficLevel=25,npcLevel=35,parkedVehicleLevel=25,emergencyVehicles=true,militaryVehicles=true,actions={traffic=true,npc=true,parked=true,emergency=true,military=true,events=true,zones=true}},
 {id='sheriff',name='Sheriff',jobs={'sheriff'},minimumGrade=0,priority=45,mode='emergency',trafficLevel=40,npcLevel=45,parkedVehicleLevel=40,emergencyVehicles=true,militaryVehicles=false,actions={traffic=true,npc=true,parked=true,emergency=true,military=false,events=true,zones=true}}
}}
Config.RealismZones = {enabled=true,highwayTypes={'highway','race'},highwayTrafficBonus=15,highwayNPCBonus=5,cityTraffic=70,cityNPC=70,cityParked=75}
Config.Diagnostics = {enabled=true,historySize=60,recoveryInterval=5000}

Config.Deployables = {
 enabled=true, maxPerPlayer=18, maxTotal=160, placementDistance=3.0, removeDistance=8.0,
 spikeRadius=2.2, spikeCooldown=10000, requireDuty=true, sceneCleanupRadius=45.0,
 models={cone='prop_roadcone02a',barrier='prop_barrier_work05',police_barrier='prop_barrier_work06a',spikes='p_ld_stinger_s',flare='prop_flare_01'},
 enabledProps={cone=true,barrier=true,police_barrier=true,spikes=true,flare=true},
 kits={
  traffic_stop={{type='cone',x=-1.4,y=1.0},{type='cone',x=1.4,y=1.0},{type='cone',x=-2.0,y=3.0},{type='cone',x=2.0,y=3.0},{type='police_barrier',x=0,y=5.0}},
  road_closure={{type='barrier',x=-3.0,y=2.0},{type='barrier',x=0,y=2.0},{type='barrier',x=3.0,y=2.0},{type='cone',x=-3.0,y=4.0},{type='cone',x=3.0,y=4.0}},
  checkpoint={{type='cone',x=-3.0,y=1.0},{type='cone',x=3.0,y=1.0},{type='cone',x=-3.0,y=4.0},{type='cone',x=3.0,y=4.0},{type='police_barrier',x=0,y=6.0}},
  accident_scene={{type='cone',x=-2.5,y=1.0},{type='cone',x=2.5,y=1.0},{type='cone',x=-3.5,y=3.5},{type='cone',x=3.5,y=3.5},{type='barrier',x=0,y=5.0},{type='flare',x=-2.0,y=6.0},{type='flare',x=2.0,y=6.0}}
 }
}
