import Foundation

public class GameFieldArray {
    private var gameField: [[Cell?]]
    public let width: Int
    public let height: Int
    
    public init(_ width: Int, _ height: Int) {
        self.width = width
        self.height = height
        gameField = .init(repeating: .init(repeating: nil, count: height), count: width)
    }
    
    public init(with gameFieldArray: GameFieldArray) {
        self.width = gameFieldArray.width
        self.height = gameFieldArray.height
        gameField = .init(repeating: .init(repeating: nil, count: height), count: width)
        gameFieldArray.allCells().forEach(self.put)
    }
    
    subscript(x: Int, y: Int) -> Cell? {
        get { let (ix, iy) = indicesFromCyclic(x, y); return gameField[ix][iy] }
        set { let (ix, iy) = indicesFromCyclic(x, y); gameField[ix][iy] = newValue }
    }
    
    subscript(pos: (x: Int, y: Int)) -> Cell? {
        get { return self[pos.x, pos.y] }
        set { self[pos.x, pos.y] = newValue }
    }
    
    func isEmpty(at x: Int, _ y: Int) -> Bool {
        return self[x, y] == nil
    }
    
    func isEmpty(at pos: (x: Int, y: Int)) -> Bool {
        return isEmpty(at: pos.x, pos.y)
    }
    
    func put(_ cell: Cell) {
        self[cell.pos] = cell
    }
    
    func allCells() -> [Cell] {
        return gameField.reduce([], +).compactMap{$0}
    }

    
    private func indicesFromCyclic(_ x: Int, _ y: Int) -> (Int, Int) {
        var ix = x % width
        var iy = y % height
        if ix < 0 {
            ix = width + ix
        }
        if iy < 0 {
            iy = height + iy
        }
        return (ix, iy)
    }
    
    private func indicesFromCyclic(_ pos: (x: Int, y: Int)) -> (Int, Int) {
        return indicesFromCyclic(pos.x, pos.y)
    }
}

public class GameField {
    public var acceptedCells: [Cell]
    public var unacceptedCells: [Cell]
    public var gameField: GameFieldArray
    
    var prevUnacceptedCells: [Cell]
    var prevGameField: GameFieldArray
    
    public let width: Int
    public let height: Int
    
    public init(_ width: Int, _ height: Int) {
        self.width               = width
        self.height              = height
        self.acceptedCells       = []
        self.unacceptedCells     = []
        self.prevUnacceptedCells = []
        self.gameField           = GameFieldArray(width, height)
        self.prevGameField       = GameFieldArray(width, height)
    }
    
    /*
    init(with cells: [Cell], cycle: Int) {
        placeCells     = []
        prevPlaceCells = []
        gameField     = .init(repeating: nil, count: width*height)
        prevGameField = .init(repeating: nil, count: width*height)
        cells.forEach(placeCell)
    }
    */
    
    public func updateForNewCycle() {
        // Discard unaccepted cells from the prev game cycle
        prevUnacceptedCells = []
        
        // Recalc current game field
        calcCurrentGameField()
        removeCurrentlyPlacedCellsIfConflicts()
        
        // Bake accepted cells to the game field
        acceptedCells.forEach(gameField.put)
        
        // Move current unaccepted cells to previous
        prevUnacceptedCells = unacceptedCells
        
        // Move current game filed to the previous
        prevGameField = gameField
        
        // Clear current accepted and unaccepted cells
        acceptedCells   = []
        unacceptedCells = []
        
        // Recalc current game field
        calcCurrentGameField()
    }
    
    public func canPlaceCell(_ cell: Cell) -> Bool {
        return gameField.isEmpty(at: cell.pos)
            && acceptedCells.allSatisfy{$0.pos != cell.pos}
            && unacceptedCells.allSatisfy{$0.pos != cell.pos}
    }
    
    public func placeAcceptedCell(_ cell: Cell) {
        acceptedCells.append(cell)
        unacceptedCells.removeAll{$0.pos == cell.pos}
        prevUnacceptedCells.removeAll{$0.pos == cell.pos}
        
        // recalc game field
        calcCurrentGameField()
        
        // remove current unaccepded and accepted cells in case of conflict
        removeCurrentlyPlacedCellsIfConflicts()
    }
    
    public func placeUnacceptedCell(_ cell: Cell) {
        unacceptedCells.append(cell)
    }
    
    public func canPlaceCellInPrevCycle(_ cell: Cell) -> Bool {
        return prevGameField.isEmpty(at: cell.pos)
            && prevUnacceptedCells.allSatisfy{$0.pos != cell.pos}
    }
    
    public func placeCellInPrevCycle(_ cell: Cell) {
        // remove from unaccepted if exists
        prevUnacceptedCells.removeAll { $0.pos == cell.pos }
        
        // place to prev game field
        prevGameField.put(cell)
        
        // recalc game field
        calcCurrentGameField()
        
        // remove current unaccepded cells in case of conflict
        removeCurrentlyPlacedCellsIfConflicts()
    }
    
    public func calcCurrentGameField() {
        gameField = GameFieldArray(with: prevGameField)
        prevUnacceptedCells.forEach(gameField.put)
        
        // TODO: Add life
        func getNeighbors(_ x: Int, _ y: Int) -> [Cell] {
            return [
                gameField[x-1, y-1],
                gameField[x-1, y  ],
                gameField[x-1, y+1],
                gameField[x  , y-1],
                gameField[x  , y+1],
                gameField[x+1, y-1],
                gameField[x+1, y  ],
                gameField[x+1, y+1]
                ].compactMap{$0}
        }
        
        var cellsToPut = [Cell]()
        var cellsToRemove = [Cell]()
        
        for x in 0..<gameField.width {
            for y in 0..<gameField.height {
                let neighbors = getNeighbors(x, y)
                let cell = gameField[x,y]
                
                // give birth if there are min two cells of the same user
                if cell == nil && neighbors.count == 3 {
                    let midCell = neighbors.sorted{$0.userId < $1.userId}[1]
                    if (neighbors.filter{$0.userId == midCell.userId}).count >= 2 {
                        let newCell = Cell(pos: (x:x, y:y), userId: midCell.userId, color: midCell.color)
                        cellsToPut.append(newCell)
                    }
                }
                
                // death
                if cell != nil && (neighbors.count < 2 || neighbors.count > 3) {
                    cellsToRemove.append(cell!)
                }
            }
        }
        
        cellsToPut.forEach(gameField.put)
        cellsToRemove.forEach{gameField[$0.pos] = nil}
    }
    
    public func removeCurrentlyPlacedCellsIfConflicts() {
        acceptedCells.removeAll { self.gameField.isEmpty(at: $0.pos) == false }
        unacceptedCells.removeAll { self.gameField.isEmpty(at: $0.pos) == false }
    }
}
