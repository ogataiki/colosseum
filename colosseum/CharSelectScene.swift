import SpriteKit

class CharSelectScene: SKScene, SpeechDelegate, UITableViewDelegate, UITableViewDataSource {
    
    enum SceneStatus: Int {
        case pretreat = -1
        case idle = 0
    }
    var scene_status = SceneStatus.pretreat;

    var game_mgr = GameManager.instance;
    var char_list = GameManager.getBattleCharList();
    
    var story_mgr = StoryManager.instance;
    
    var tableView: UITableView!;
    var enterBtn: UIButton!;
    var cancelBtn: UIButton!;
    
    var selected_name: String = "";
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        
        // これしないと孫要素の表示順がおかしくなる
        view.ignoresSiblingOrder = false;
        
        tableView = UITableView(frame: CGRectMake(0, self.size.height*0.5, self.size.width*0.55, self.size.height*0.4), style: UITableViewStyle.Plain);
        tableView.dataSource = self;
        tableView.delegate = self;
        view.addSubview(tableView);
        
        enterBtn = UIButton(frame: CGRectMake(self.size.width*0.3, self.size.height*0.6, self.size.width*0.4, self.size.width*0.2));
        enterBtn.backgroundColor = UIColor.greenColor();
        enterBtn.titleLabel!.lineBreakMode = NSLineBreakMode.ByWordWrapping;
        enterBtn.setTitle("いい", forState: UIControlState.Normal)
        enterBtn.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        enterBtn.setTitle("いい", forState: UIControlState.Highlighted)
        enterBtn.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Highlighted)
        enterBtn.addTarget(self, action: "enter", forControlEvents: UIControlEvents.TouchUpInside);
        self.view!.addSubview(enterBtn);

        cancelBtn = UIButton(frame: CGRectMake(self.size.width*0.3, self.size.height*0.75, self.size.width*0.4, self.size.width*0.2));
        cancelBtn.backgroundColor = UIColor.orangeColor();
        cancelBtn.titleLabel!.lineBreakMode = NSLineBreakMode.ByWordWrapping;
        cancelBtn.setTitle("だめ", forState: UIControlState.Normal)
        cancelBtn.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        cancelBtn.setTitle("だめ", forState: UIControlState.Highlighted)
        cancelBtn.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Highlighted)
        cancelBtn.addTarget(self, action: "cancel", forControlEvents: UIControlEvents.TouchUpInside);
        self.view!.addSubview(cancelBtn);
        
        enterBtn.hidden = true;
        cancelBtn.hidden = true;

        naviStart();
        
        scene_status = .idle;
    }
    
    func enter() {
        
        tableView.removeFromSuperview();
        enterBtn.removeFromSuperview();
        cancelBtn.removeFromSuperview();
        
        game_mgr.enemy_character = CharManager.cnvStringToCharNames(selected_name)!;
        
        SceneManager.changeScene(SceneManager.Scenes.battle);
    }
    
    func cancel() {
        selected_name = "";
        
        tableView.hidden = false;
        
        enterBtn.hidden = true;
        cancelBtn.hidden = true;
    }
    
    //---------------
    // ナビ
    var navi: SpeechCtrl!;
    var speechRunning = StoryManager.SpeechNum.non;
    var speechs: [String] = [];
    func naviStart() {
        speechs = [story_mgr.getSpeech_naviCharSelect()];
        if speechs.count <= 0 {
            return;
        }
        speechRunning = StoryManager.SpeechNum.navi_char_select;
        navi = SpeechCtrl(_scene: self
            , _speaker_image: "NaviChar"
            , _speaker_position: CGPointMake(self.size.width*0.85+self.size.width, self.size.height*0.4)
            , _zPosition: 0
            , _speechs: speechs
            , _delegate: self);
        navi.run();
    }
    func callbackSpeechFinish(index: Int) {
        
    }
    

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        /* Called when a touch begins */
        
        for touch in (touches ) {
            let location = touch.locationInNode(self)
            
        }
    }
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        
    }
 
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int  {
        return char_list.count;
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath:NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "Cell")
        cell.textLabel!.text = char_list[indexPath.row].displayName;
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath:NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false);
        tableView.hidden = true;
        selected_name = char_list[indexPath.row].name!;
        navi.reset { () -> Void in
            self.navi.speechs = ["「\(self.char_list[indexPath.row].displayName)」にするかね？"];
            self.navi.run(true);
            
            self.enterBtn.hidden = false;
            self.cancelBtn.hidden = false;
        }
    }
}