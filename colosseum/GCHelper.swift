import GameKit

/// Custom delegate used to provide information to the application implementing GCHelper.
public protocol GCHelperDelegate {
    
    /// Method called when a match has been initiated.
    func matchStarted()
    
    /// Method called when the device received data about the match from another device in the match.
    func match(match: GKMatch, didReceiveData: NSData, fromPlayer: String)
    
    /// Method called when the match has ended.
    func matchEnded()
}

/// A GCHelper instance represents a wrapper around a GameKit match.
final class GCHelper: NSObject, GKMatchmakerViewControllerDelegate, GKGameCenterControllerDelegate, GKMatchDelegate, GKLocalPlayerListener {
    
    /// The match object provided by GameKit.
    var match: GKMatch!
    
    private var delegate: GCHelperDelegate?
    private var invite: GKInvite!
    private var invitedPlayer: GKPlayer!
    private var playersDict = [String:AnyObject]()
    private var presentingViewController: UIViewController!
    
    private var authenticated = false
    private var matchStarted = false
    
    /// The shared instance of GCHelper, allowing you to access the same instance across all uses of the library.
    static let instance = GCHelper()
    
    override init() {
        super.init()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "authenticationChanged", name: GKPlayerAuthenticationDidChangeNotificationName, object: nil)
    }
    
    // MARK: Internal functions
    
    func authenticationChanged() {
        if GKLocalPlayer.localPlayer().authenticated && !authenticated {
            println("Authentication changed: player authenticated")
            authenticated = true
        } else {
            println("Authentication changed: player not authenticated")
            authenticated = false
        }
    }
    
    private func lookupPlayers() {
        let playerIDs = match.players.map { ($0 as! GKPlayer).playerID }
        
        GKPlayer.loadPlayersForIdentifiers(playerIDs) { (players, error) -> Void in
            if error != nil {
                println("Error retrieving player info: \(error.localizedDescription)")
                self.matchStarted = false
                self.delegate?.matchEnded()
            } else {
                for player in players {
                    println("Found player: \(player.alias)")
                    self.playersDict[(player as! GKPlayer).playerID] = player
                }
                
                self.matchStarted = true
                GKMatchmaker.sharedMatchmaker().finishMatchmakingForMatch(self.match)
                self.delegate?.matchStarted()
            }
        }
    }
    
    // MARK: User functions
    
    /// Authenticates the user with their Game Center account if possible
    func authenticateLocalUser() {
        println("Authenticating local user...")
        if GKLocalPlayer.localPlayer().authenticated == false {
            GKLocalPlayer.localPlayer().authenticateHandler = { (view, error) in
                if error == nil {
                    self.authenticated = true
                } else {
                    println("\(error.localizedDescription)")
                }
            }
        } else {
            println("Already authenticated")
        }
    }
    
    /**
        Attempts to pair up the user with other users who are also looking for a match.
        
        :param: minPlayers The minimum number of players required to create a match.
        :param: maxPlayers The maximum number of players allowed to create a match.
        :param: viewController The view controller to present required GameKit view controllers from.
        :param: delegate The delegate receiving data from GCHelper.
    */
    func findMatchWithMinPlayers(minPlayers: Int, maxPlayers: Int, viewController: UIViewController, delegate theDelegate: GCHelperDelegate) {
        matchStarted = false
        match = nil
        presentingViewController = viewController
        delegate = theDelegate
        presentingViewController.dismissViewControllerAnimated(false, completion: nil)
        
        let request = GKMatchRequest()
        request.minPlayers = minPlayers
        request.maxPlayers = maxPlayers
        
        let mmvc = GKMatchmakerViewController(matchRequest: request)
        mmvc.matchmakerDelegate = self
        
        presentingViewController.presentViewController(mmvc, animated: true, completion: nil)
    }
    
    /**
        Reports progress on an achievement to GameKit.
        
        :param: identifier A string that matches the identifier string used to create an achievement in iTunes Connect.
        :param: percent A percentage value (0 - 100) stating how far the user has progressed on the achievement.
    */
    func reportAchievementIdentifier(identifier: String, percent: Double) {
        let achievement = GKAchievement(identifier: identifier)
        
        achievement?.percentComplete = percent
        achievement?.showsCompletionBanner = true
        GKAchievement.reportAchievements([achievement!]) { (error) -> Void in
            if error != nil {
                println("Error in reporting achievements: \(error)")
            }
        }
    }
    
    /**
        Reports a high score eligible for placement on a leaderboard to GameKit.
        
        :param: identifier A string that matches the identifier string used to create a leaderboard in iTunes Connect.
        :param: score The score earned by the user.
    */
    func reportLeaderboardIdentifier(identifier: String, score: Int) {
        let scoreObject = GKScore(leaderboardIdentifier: identifier)
        scoreObject.value = Int64(score)
        GKScore.reportScores([scoreObject]) { (error) -> Void in
            if error != nil {
                println("Error in reporting leaderboard scores: \(error)")
            }
        }
    }
    
    /**
        Presents the game center view controller provided by GameKit.
        
        :param: viewController The view controller to present GameKit's view controller from.
        :param: viewState The state in which to present the new view controller.
    */
    func showGameCenter(viewController: UIViewController, viewState: GKGameCenterViewControllerState) {
        presentingViewController = viewController
        
        let gcvc = GKGameCenterViewController()
        gcvc.viewState = viewState
        gcvc.gameCenterDelegate = self
        presentingViewController.presentViewController(gcvc, animated: true, completion: nil)
    }
    
    // MARK: GKGameCenterControllerDelegate
    
    func gameCenterViewControllerDidFinish(gameCenterViewController: GKGameCenterViewController!) {
        presentingViewController.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: GKMatchmakerViewControllerDelegate
    
    func matchmakerViewControllerWasCancelled(viewController: GKMatchmakerViewController!) {
        presentingViewController.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func matchmakerViewController(viewController: GKMatchmakerViewController!, didFailWithError error: NSError!) {
        presentingViewController.dismissViewControllerAnimated(true, completion: nil)
        println("Error finding match: \(error.localizedDescription)")
    }
    
    func matchmakerViewController(viewController: GKMatchmakerViewController!, didFindMatch theMatch: GKMatch!) {
        presentingViewController.dismissViewControllerAnimated(true, completion: nil)
        match = theMatch
        match.delegate = self
        if !matchStarted && match.expectedPlayerCount == 0 {
            println("Ready to start match!")
            self.lookupPlayers()
        }
    }
    
    // MARK: GKMatchDelegate
    
    func match(theMatch: GKMatch!, didReceiveData data: NSData!, fromPlayer playerID: String!) {
        if match != theMatch {
            return
        }
        
        delegate?.match(theMatch, didReceiveData: data, fromPlayer: playerID)
    }
    
    func match(theMatch: GKMatch!, player playerID: String!, didChangeState state: GKPlayerConnectionState) {
        if match != theMatch {
            return
        }
        
        switch state {
        case .StateConnected where !matchStarted && theMatch.expectedPlayerCount == 0:
            lookupPlayers()
        case .StateDisconnected:
            matchStarted = false
            delegate?.matchEnded()
            match = nil
        default:
            break
        }
    }
    
    func match(theMatch: GKMatch!, didFailWithError error: NSError!) {
        if match != theMatch {
            return
        }
        
        println("Match failed with error: \(error.localizedDescription)")
        matchStarted = false
        delegate?.matchEnded()
    }
    
    // MARK: GKLocalPlayerListener
    
    func player(player: GKPlayer!, didAcceptInvite inviteToAccept: GKInvite!) {
        let mmvc = GKMatchmakerViewController(invite: inviteToAccept)
        mmvc.matchmakerDelegate = self
        presentingViewController.presentViewController(mmvc, animated: true, completion: nil)
    }
    
    func player(player: GKPlayer!, didRequestMatchWithOtherPlayers playersToInvite: [AnyObject]!) {
    }
}
