import SpriteKit

class GaugeBase: SKCropNode
{
    var gaugeSprite: SKSpriteNode!;
    
    override init() {
        super.init()
        
        gaugeSprite = SKSpriteNode(color: UIColor.greenColor(), size: CGSizeMake(300, 40));
        initGauge();
        addChild(gaugeSprite)
    }
    
    init(color: UIColor, size: CGSize, anchor: CGPoint = CGPointZero) {
        super.init()
        
        gaugeSprite = SKSpriteNode(color: color, size: size);
        initGauge(anchor: anchor);
        addChild(gaugeSprite)
    }
    
    init(imageNamed: String, anchor: CGPoint = CGPointZero) {
        super.init()

        gaugeSprite = SKSpriteNode(imageNamed: imageNamed);
        initGauge(anchor: anchor);
        addChild(gaugeSprite)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initGauge(
        anchor: CGPoint = CGPointZero) {
        
        gaugeSprite.anchorPoint = anchor;
        let maskSprite = SKSpriteNode(color: SKColor.blackColor(), size: gaugeSprite.size);
        maskSprite.anchorPoint = anchor;
        self.maskNode = maskSprite;
    }
    
    func updateScale(#x: CGFloat, y: CGFloat)
    {
        self.maskNode?.xScale = x;
        self.maskNode?.yScale = y;
    }
}

class Gauge: SKSpriteNode
{
    var lange: CGFloat = 100.0;
    var limit: CGFloat = 100.0;
    var value: CGFloat = 0.0;

    enum Direction: Int {
        case horizontal = 0
        case vertical = 1
    }
    var direction: Direction = Direction.horizontal;

    var gauge: GaugeBase!;
    var gauge_lo: GaugeBase!;
        
    func initGauge(#color: UIColor, direction: Direction, zPos: CGFloat) {
    
        self.direction = direction;
        
        gauge = GaugeBase(color: color, size: size);
        updateGaugePosition();
        gauge.zPosition = zPos;
        addChild(gauge)
    }
    
    func initGauge(#imageNamed: String, direction: Direction, zPos: CGFloat) {
        
        self.direction = direction;
        
        gauge = GaugeBase(imageNamed: imageNamed);
        updateGaugePosition();
        gauge.zPosition = zPos;
        addChild(gauge)
    }
    
    func initGauge_lo(#color: UIColor, zPos: CGFloat) {
        
        gauge_lo = GaugeBase(color: color, size: self.size, anchor: CGPointMake(1.0, 1.0));
        updateGaugePosition();
        gauge_lo.zPosition = zPos;
        addChild(gauge_lo)
    }

    func initGauge_lo(#imageNamed: String, zPos: CGFloat) {
        
        gauge_lo = GaugeBase(imageNamed: imageNamed, anchor: CGPointMake(1.0, 1.0));
        updateGaugePosition();
        gauge_lo.zPosition = zPos;
        addChild(gauge_lo)
    }

    func changeAnchorPoint(point: CGPoint) {
        self.anchorPoint = point;
        updateGaugePosition();
    }
    
    func changePosition(point: CGPoint) {
        self.position = point;
        updateGaugePosition();
    }
    
    func updateGaugePosition() {
        let xAnchor = anchorPoint.x;
        let yAnchor = anchorPoint.y;
        if let g = gauge {
            g.position = CGPointMake(0 - (self.size.width * xAnchor), 0 - (self.size.height * yAnchor));
        }
        if let g_lo = gauge_lo {
            g_lo.position = CGPointMake(self.size.width * xAnchor, self.size.height * yAnchor);
        }
    }
    
    func resetProgress(progress: CGFloat) {
        value = progress;
        updateScale();
    }
    
    func updateProgress(progress:CGFloat){
        value = progress;
        if value > lange {
            value = value - lange;
        }
        updateScale();
    }
    
    func updateScale()
    {
        if self.direction == Direction.vertical {
            if lange <= 0.0 {
                if let g = gauge {
                    g.updateScale(x: 1, y: 0);
                }
                if let g_lo = gauge_lo {
                    g_lo.updateScale(x: 1, y: 0);
                }
            }
            else {
                if let g = gauge {
                    g.updateScale(x: 1, y: value / lange);
                }
                if let g_lo = gauge_lo {
                    g_lo.updateScale(x: 1, y: 1 - (value / lange));
                }
            }
        }
        else {
            if lange <= 0.0 {
                if let g = gauge {
                    g.updateScale(x: 0, y: 1);
                }
                if let g_lo = gauge_lo {
                    g_lo.updateScale(x: 0, y: 1);
                }
            }
            else {
                if let g = gauge {
                    g.updateScale(x: value / lange, y: 1);
                }
                if let g_lo = gauge_lo {
                    g_lo.updateScale(x: 1 - (value / lange), y: 1);
                }
            }
        }
    }

}
