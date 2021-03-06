//
//  ContentView.swift
//  fulltardie
//
//  Created by c.p.brown 2021

// TODO

// [X] = done
// [!] = doing it
// [-] = probably not doing it
// [?] = having proiblems with it

// - [X] fulltardie
// - [X] translate datastructure for swift
// - [X] translate findnextdate for swift
// - [X] commandline tests
// - [X] handle day counting from date
// - [X] add day offset
// - [X] handle date ranges

// - [!] forecast tab
// - [X] forecast on load
// - [ ] category colors
// - [ ] running balance
// - [!] forecast options ui
// - [?] forecast switch: next (default), range -- toggle only works on 3rd activation
// - [-] forecast date for range end if active
// - [ ] double tap to go to governing rule
// - [ ] respect system theme, adjust category colors accordingly
// - [ ] persistent mode (shows past items until checked)
// - [ ] add checkbox to items in persistent mode
// - [ ] remove checked in persistent mode
// - [X] fix swiftui foreach index duplicate entry issue

// - [!] scenario tab
// - [X] fallback default scenario
// - [ ] app file storage dir
// - [ ] new scenario
// - [ ] remove scenario
// - [ ] import scenario
// - [ ] rename scenario
// - [ ] export scenario
// - [ ] safety checks for import
// - [ ] autosave toggle

// - [ ] setup tab
// - [ ] new rule
// - [ ] delete rule
// - [ ] edit rule
// - [ ] plain-english parameters
// - [ ] reflow parameters
// - [ ] duplicate rule
// - [ ] reforecast after edit

// - [ ] category tab
// - [ ] add category
// - [ ] remove category
// - [ ] rename category
// - [ ] category color
// - [ ] category color to none/fg/bg switch

// - [ ] graph tab
// - [ ] stacked bar graph
// - [ ] adapt to screen orientation
// - [ ] use category colors
// - [ ] adapt to ranges on display
// - [ ] pan and zoom
// - [ ] double-tap bg to fit
// - [ ] select bars to pop-up info
// - [ ] double-tap bar to go to governing rule

// - [!] swiftui
// - [!] respect system theme
// - [!] maximize screen usage
// - [!] all params within right-had thumb reach
// - [ ] prevent vkb blocking params (shift ui up)
// - [!] optimize
// - [ ] app icon
// - [ ] tab icons
// - [ ] fix scroll lag

// - [-] ipad ui adjustments -- fucking ipad battery died right after warranty expired
// - [-] 2-pane ui
// - [-] font scaling

// - [ ] interoperability with osx version

// - [ ] testing
// - [ ] personally hostile
// - [ ] illiterate
// - [ ] lazy
// - [ ] pedant
// - [ ] profoudnly stupid

// - [ ] abandon this project, start a new pinephone/posh version



import SwiftUI

// required for date
import Foundation


// true modulo from 'cdeerinck'
// https://stackoverflow.com/questions/41180292/negative-number-modulo-in-swift#41180619

infix operator %%

extension Int {
    static  func %% (_ left: Int, _ right: Int) -> Int {
        if left >= 0 { return left % right }
        if left >= -right { return (left+right) }
        return ((left % right)+right)%right
    }
}

func lmyd(cy: Int) -> [Int] {
    var t = [0,31,28,31,30,31,30,31,31,30,31,30,31]
    let ly = (cy % 100 == 0) ? (cy % 400 == 0) : (cy % 4 == 0)
    if ly { t[2] = 29 }
    return t
}

func prepadstr(str: String,len: Int,wth: String) -> String {
    var o = str
    while o.count < len {
        o = wth + o
    }
    return o
}

// test lmyd
//let args = CommandLine.arguments
//var yr = 2020
//if args.count > 1 {
//    if let yy = Int(args[1]) { yr = yy }
//}
//print("number of days in each month for \(yr) are : \(lmyd(cy:yr))")


struct Rule {
    var evr = 0
    var nth = 0
    var dfr = 0
    var wkd = 0
    var mth = 0
    var mfr = 0
    var yfr = 0
    var amt = 0.0
    var cat = ""
    var inf = ""
}

struct Result: Identifiable {
    let id: UUID
    var dky: String
    var hrd: Date
    var amt: Double
    var cat: String
    var inf: String
}

func findnextdate(dt: Rule, n: [Int]) -> Result {

    var doof = 1
    var o: Result = Result(id: UUID(), dky: "", hrd: Date(), amt: dt.amt, cat: dt.cat, inf: dt.inf)

    let ofs = dt.evr
    let nth = dt.nth
    var fdy = dt.dfr
    let ofm = dt.mth
    var fmo = dt.mfr
    var fye = dt.yfr
    var mth = nth
    let dwkd = dt.wkd

    //let wkds = ["0","monday","tuesday","wednesday","thursday","friday","saturday","sunday","nowke","nowke_b","nowke_a"]
    //let wkd = wkds[dwkd]

// set dt components to now if its zero
    
    if fmo == 0 { fmo = n[1] }
    if fye == 0 { fye = n[0] }
    if fdy == 0 { fdy = n[2] }

// correct last day of month in dt if its out of range

    var t = lmyd(cy:fye)
    var md = t[fmo]
    if md < fdy { fdy = md }

// fucking onerous swift date shitfuckery....
   
    // construct date from dt
    var adc = DateComponents()
    adc.year = fye
    adc.month = fmo
    adc.day = fdy
    adc.timeZone = TimeZone(abbreviation: "UTC")
    adc.hour = 12
    adc.minute = 30
    let cc = Calendar.current
    var a = cc.date(from: adc)

    // construct date from supplied 'current' date
    var bdc = DateComponents()
    bdc.year = n[0]
    bdc.month = n[1]
    bdc.day = n[2]
    adc.timeZone = TimeZone(abbreviation: "UTC")
    let uc = Calendar.current
    let nw = uc.date(from: bdc)
    
    // construct duplicate of supplied date for iteration
    var jdc = DateComponents()
    jdc.year = fye
    jdc.month = fmo
    jdc.day = fdy
    jdc.timeZone = TimeZone(abbreviation: "UTC")
    jdc.hour = 12
    jdc.minute = 30
    var j = cc.date(from: adc)
    
    // get difference in (months + 12) between supplied data and current
    let aa = uc.ordinality(of: .day, in: .era, for: Date())
    let bb = cc.ordinality(of: .day, in: .era, for: a!)
    let dif = Int(((Double(aa! - bb!) / 7.0) / 52.0) * 12.0) + 12
    //print(" dif = \(dif)")
    
    if nth > 0 {
        // search up to (dif) months for a matching date
        for _ in 1...dif {
            var dmo = (cc.component(.month, from: a!) == fmo)
            if ofm > 0 {
                dmo = ((cc.component(.month, from: a!) - fmo) % ofm == 0)
            }
            if dmo {
                //print("    checking month: \(cc.component(.month, from:a!))")
                var c = 0
                t = lmyd(cy:(cc.component(.year,from:a!)))
                var wdc = 0
                var cdc = 0
                md = t[(cc.component(.month,from:a!))]
                //print("    weekday to check (starting from monday): \(wkd) (\(dwkd))")
                if dwkd == 0 || dwkd > 7 {
                    mth = min(nth, md)
                    if mth == 0 {
                        mth = (cc.component(.day,from:nw!))
                    }
                }
                //print("    days per month: \(md)")
                //print("    mth = \(mth)")

    // get day/weekday match counts...

                for e in 1...md {
                    jdc.day = e
                    j = cc.date(from:jdc)
                    //print("    comparing calendar weekday \(((cc.component(.weekday,from:j!) - 2) %% 7) + 1) with \(dwkd)")
                    if (((cc.component(.weekday,from:j!) - 2) %% 7) + 1) == dwkd {
                        wdc = wdc + 1
                        //print("        weekday match count = \(wdc)")
                    }
                    if e == mth {
                        cdc = cdc + 1
                    }
                }

    // find next date...

                for d in 1...md {
                    adc.day = d
                    a = cc.date(from: adc)
                    var chk = -1
                    var cwi = 0
                    if dwkd > 0 && dwkd < 8 {
                        //print("    checking weekday: \(cc.component(.weekday,from:a!)) of date: \(cc.component(.day,from:a!))")
                        if (((cc.component(.weekday,from:a!) - 2) %% 7) + 1) == dwkd {
                            //print("    found weekday match...")
                            c = c + 1
                            let rem = md - d
                            if c >= ofs || rem < 8 {
                                //print("        setting check as modulo of \(c) and minimum of \(nth) and \(wdc)")
                                chk = (c %% min(nth,wdc))
                                //print("        chk = \(chk)")
                                cwi = 0
                            }
                        }
                    }
                    if dwkd == 0 || dwkd >= 8 {
                        chk = 0
                        cwi = d % mth
                    }
                    if chk == cwi {
                        //print("    no-weekend conditions met: \(chk) == \(cwi)")
                        //print("    weekday is \((((cc.component(.weekday,from:a!) - 2) %% 7) + 1))")
                        var avd = d
                        if (((cc.component(.weekday,from:a!) - 2) %% 7) + 1) > 5 {
                            switch dwkd {
                                case 8 :
                                    avd = (d + Int(((((Double((((cc.component(.weekday,from:a!) - 2) %% 7) + 1)) - 5.0) - 1.0) / 1.0) * 2.0) - 1.0))
                                case 9 :
                                    avd = d - ((((cc.component(.weekday,from:a!) - 2) %% 7) + 1) - 5)
                                case 10 :
                                    avd = d + (3 - ((((cc.component(.weekday,from:a!) - 2) %% 7) + 1) - 5))
                                default :
                                    doof = 1
                            }
                        }
                        adc.day = avd
                        a = cc.date(from:adc)
                        if a! >= nw! {
                            //print("    found next date: \(adc.year) \(adc.month) \(adc.day)")
                            var smo = String(cc.component(.month,from:a!))
                            smo = prepadstr(str: smo,len: 2,wth: "0")
                            //print("        padded month = \(smo)")
                            var sdy = String(cc.component(.day,from:a!))
                            sdy = prepadstr(str: sdy,len: 2,wth: "0")
                            //print("        padded day = \(sdy)")
                            let syy = String(cc.component(.year,from:a!))
                            //print("        year string = \(syy)")
                            o.dky = syy+smo+sdy
                            //print("            date key = \(o.dky)")
                            //let hrdf = DateFormatter()
                            //hrdf.dateFormat = "dd MM yyyy"
                            //o.hrd = hrdf.string(from: a!)
                            o.hrd = a!
                            //print("returning found date for \(dt.inf)")
                            return o
                        }
                        if ofs == 0 { break }
                    }
                }
                adc.day = 1
                a = cc.date(from:adc)
                jdc.day = 1
                j = cc.date(from:jdc)
            }

            adc.month = adc.month! + 1
            a = cc.date(from:adc)
            jdc.month = jdc.month! + 1
            j = cc.date(from:jdc)
        }
    }

// nth is zero and offset isn't, so we're just counting days
// TODO: integrate this with the main search loop above

    if nth == 0 && ofs > 0 {
        a = cc.date(byAdding: .day, value: ofs, to: a!)!
        var avd = cc.component(.day,from:a!)
        var d = avd
        if (((cc.component(.weekday,from:a!) - 2) %% 7) + 1) > 5 {
            switch dwkd {
                case 8 :
                    avd = (d + Int(((((Double((((cc.component(.weekday,from:a!) - 2) %% 7) + 1)) - 5.0) - 1.0) / 1.0) * 2.0) - 1.0))
                case 9 :
                    avd = d - ((((cc.component(.weekday,from:a!) - 2) %% 7) + 1) - 5)
                case 10 :
                    avd = d + (3 - ((((cc.component(.weekday,from:a!) - 2) %% 7) + 1) - 5))
                default :
                    doof = 1
            }
            adc.day = avd
            a = cc.date(from:adc)
        }

        let smo = String(cc.component(.month,from:a!))
        let sdy = String(cc.component(.day,from:a!))
        let syy = String(cc.component(.year,from:a!))
        let hrdf = DateFormatter()
        //hrdf.dateFormat = "dd MM yyyy"
        //o.hrd = hrdf.string(from: a!)
        o.hrd = a!
        o.dky = syy+smo+sdy
        //print("returning a day-count result...")
        return o
    }

// return unfilled result nothing is found, this will get ingored by the recieving function

    return o
}

// sample data
// every-nth, nth-day, from-day, weekday, nth-month, from-month, from-year

var dat = [
    Rule (
        evr: 1,
        nth: 1,
        dfr: 0,
        wkd: 7,
        mth: 1,
        mfr: 11,
        yfr: 0,
        amt: -5.00,
        cat: "CSH",
        inf: "every sunday of every month starting from this november"
    ),
    Rule (
        evr: 2,
        nth: 2,
        dfr: 0,
        wkd: 1,
        mth: 1,
        mfr: 0,
        yfr: 0,
        amt: -10.00,
        cat: "CSH",
        inf: "every 2nd and 4th monday of every month starting this month"
    ),
    Rule (
        evr: 1,
        nth: 6,
        dfr: 0,
        wkd: 4,
        mth: 3,
        mfr: 2,
        yfr: 0,
        amt: -20.00,
        cat: "CSH",
        inf: "every last thursday of every 3rd month starting february this year"
    ),
    Rule (
        evr: 1,
        nth: 26,
        dfr : 0,
        wkd: 8,
        mth: 1,
        mfr: 0,
        yfr: 0,
        amt: -10.00,
        cat: "CSH",
        inf: "every weekday closest to the 26th of the month starting this month"
    ),
    Rule (
        evr: 1,
        nth: 33,
        dfr: 0,
        wkd: 0,
        mth: 12,
        mfr: 2,
        yfr: 0,
        amt: -10.00,
        cat: "CSH",
        inf: "every last day of february"
    ),
    Rule (
        evr: 0,
        nth: 8,
        dfr: 0,
        wkd: 0,
        mth: 0,
        mfr: 8,
        yfr: 0,
        amt: -100.00,
        cat: "CSH",
        inf: "every 8th of august"
    ),
    Rule (
        evr: 0,
        nth: 8,
        dfr : 0,
        wkd: 9,
        mth: 1,
        mfr: 11,
        yfr: 0,
        amt: -10.00,
        cat: "CSH",
        inf: "every weekday on or before the 8th of every month starting november"
    ),
    Rule (
        evr: 14,
        nth: 14,
        dfr: 0,
        wkd: 10,
        mth: 1,
        mfr: 0,
        yfr: 0,
        amt: -50.00,
        cat: "CSH",
        inf: "every weekday on or after th 14th and 28th of every month"
    ),
    Rule (
        evr: 1,
        nth: 30,
        dfr: 0,
        wkd: 8,
        mth: 2,
        mfr: 10,
        yfr: 0,
        amt: -10.00,
        cat: "CSH",
        inf: "every weekday on or before the 30th of every second month starting october"
    ),
    Rule (
        evr: 14,
        nth: 0,
        dfr: 17,
        wkd: 8,
        mth: 1,
        mfr: 10,
        yfr: 0,
        amt: -10.00,
        cat: "CSH",
        inf: "every weekday on or before every 14 days from october 17th this year"
    )
]


let date = Date()
let cc = Calendar.current
let nn = [cc.component(.year, from: date), cc.component(.month, from: date),cc.component(.day, from: date)]

var ded = Calendar.current.date(byAdding: .year, value: 1, to: date)

//check for saved data on disk...

var pth = ""

func loaddat() {
    //print("loaddat started...")
    var idat = ""
    if let pth = Bundle.main.path(forResource: "saved", ofType: "csv") {
      do {
        idat = try String(contentsOfFile: pth)
        } catch {
            print(" saved.csv not found, using test data instead...")
        }
    }

    //try to populate data from sdat if it exists
    if idat.count > 0 {
        dat = []
        //print(" idat found, extracting data...")
        let  ida = idat.components(separatedBy: .newlines)
    // process rows, skip header
        for u in 1...(ida.count-1) {
            //print("ida[u] = \(ida[u])")
            let rc = ida[u].split(separator: ";").map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            //print("columns = \(rc)")
            if rc.count == 10 {
                var d: Rule! = Rule()
                d.evr = Int(rc[0]) ?? 0
                d.nth = Int(rc[1]) ?? 0
                d.dfr = Int(rc[2]) ?? 0
                d.wkd = Int(rc[3]) ?? 0
                d.mth = Int(rc[4]) ?? 0
                d.mfr = Int(rc[5]) ?? 0
                d.yfr = Int(rc[6]) ?? 0
                d.amt = Double(rc[7]) ?? 0.0
                d.cat = rc[8]
                d.inf = rc[9]
                dat.append(d)
            }
        }
    }
    //print("loaddat complete.")
}

var forecasttable = ""
var maxlen = [0,0,0,0,0,0]
var sortedforecast : [Result] = []
var hl = String("").padding(toLength: (maxlen[5]), withPad: "-", startingAt: 0)
var gdorng = true

func printmemydate (myd: Date) -> String {
    var o = ""
    let hrdf = DateFormatter()
    hrdf.dateFormat = "dd MM yyyy"
    o = hrdf.string(from: myd)
    return o
}

func renderdat(dorange: Bool, endd: Date) {
    //print("renderdat started...")
    // set maxlen for padding terminal output
    maxlen = [0,0,0,0,0,0]

    //get next date using sample data

    var forecast : [Result] = []
    //print("sample data: \(dat)")
    //print("    dat.count = \(dat.count)")
    for s in 0...(dat.count-1) {
        //print("processing data row: \n\(dat[s])\n")
        let row = dat[s]
    // collect transactions over a range, else just grab next transaction
        if dorange {
        // more reatarded swift date fuckery
            //let wut = Calendar.current
            //let huh = Calendar.current
            var sta = Date().timeIntervalSince1970 as? Double
            let sto = endd.timeIntervalSince1970 as? Double
            //print("    initial start ordinal is \(sta!)")
            //print("    stop ordinal is......... \(sto!)")
        // keep shifting start date to found date and search from there until start ordinal > stop ordinal
            while sto! > sta! {
                var dsta = Date(timeIntervalSince1970: sta!)
                //print("        start date from ordinal is \(dsta)")
                let cuc = Calendar.current
                let nwn = [cuc.component(.year, from: dsta), cuc.component(.month, from: dsta),cuc.component(.day, from: dsta)]
                let nxt = findnextdate(dt: row, n:nwn)
                if nxt.dky != "" {
                    let inc = nxt.hrd.timeIntervalSince1970 as? Double
                    //print("            entry ordinal is \(inc!)")
                    dsta = Date(timeIntervalSince1970: sta!)
                    //print("            entry date is... \(dsta)")
                    if inc! >= sta! {
                        var vs = String(nxt.dky).count
                        if vs > maxlen[0] { maxlen[0] = vs }

                        let hrdf = DateFormatter()
                        hrdf.dateFormat = "dd MM yyyy"
                        let tds = hrdf.string(from: nxt.hrd)
                        vs = String(tds).count
                        if vs > maxlen[1] { maxlen[1] = vs }
                        
                        vs = String(nxt.cat).count
                        if vs > maxlen[2] { maxlen[2] = vs }

                        vs = String(nxt.amt).count
                        if vs > maxlen[3] { maxlen[3] = vs }

                        vs = String(nxt.inf).count
                        if vs > maxlen[4] { maxlen[4] = vs }
                        
                        maxlen[5] = (maxlen[0] + maxlen[1] + maxlen[2] + maxlen[3] + maxlen[4])
                        hl = String("").padding(toLength: (maxlen[5]), withPad: "-", startingAt: 0)
                        
                        forecast.append(nxt)
                        // add a day
                        sta = (inc! + 86400.0)
                    }
            // no data, bail...
                } else {
                    break
                }
            }
        } else {
            let nxt = findnextdate(dt:row,n:nn)
            if nxt.dky != "" {
                
                var vs = String(nxt.dky).count
                if vs > maxlen[0] { maxlen[0] = vs }

                let hrdf = DateFormatter()
                hrdf.dateFormat = "dd MM yyyy"
                let tds = hrdf.string(from: nxt.hrd)
                vs = String(tds).count
                if vs > maxlen[1] { maxlen[1] = vs }
                
                vs = String(nxt.cat).count
                if vs > maxlen[2] { maxlen[2] = vs }

                vs = String(nxt.amt).count
                if vs > maxlen[3] { maxlen[3] = vs }

                vs = String(nxt.inf).count
                if vs > maxlen[4] { maxlen[4] = vs }

                maxlen[5] = (maxlen[0] + maxlen[1] + maxlen[2] + maxlen[3] + maxlen[4])
                hl = String("").padding(toLength: (maxlen[5]), withPad: "-", startingAt: 0)
                
                forecast.append(nxt)
            }
        }
    }
    //print("unsortedforecast=\(forecast)")
    sortedforecast = forecast.sorted(by: { $0.dky < $1.dky })
    forecasttable = ""
    //print("forecasttable=\(forecasttable)")
    
    // this is for commandline only
    for i in sortedforecast {
        let tds = printmemydate(myd: i.hrd)
        //print("    injected formatted date string is \(tds)")
        forecasttable = forecasttable + String("\(String(tds).padding(toLength: maxlen[1], withPad: " ", startingAt: 0)) \(i.cat) \(String(i.amt).padding(toLength: maxlen[3], withPad: " ", startingAt: 0)) \(i.inf)\n")
    }
    //print("filled forecasttable=\(forecasttable)")
    //print("renderdat complete.")
}


// hex colors, posted by 'karan champaneri' at https://stackoverflow.com/questions/56874133/use-hex-color-in-swiftui
extension Color {
    init(_ hex: Int, opacity: Double = 1.0) {
        let red = Double((hex & 0xff0000) >> 16) / 255.0
        let green = Double((hex & 0xff00) >> 8) / 255.0
        let blue = Double((hex & 0xff) >> 0) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}

struct ReportListItem: View {
    let viewmemydate: DateFormatter = {
        let mydf = DateFormatter()
        mydf.dateFormat = "dd MM yyyy"
        return mydf
    }()
    var i: Result
    var body: some View{
        VStack (spacing: 0){
            //VStack(alignment: .leading, spacing: 0.0) {
                //HStack{
            Text("\(viewmemydate.string(from: i.hrd))   \(i.cat)   \(String(format: "%.2f", i.amt))\n")
            .padding(5)
                //.multilineTextAlignment(.leading)
            .font(.custom("Monoid-Regular", size: 16))
            .frame(maxWidth: .infinity, maxHeight: 20, alignment: .leading)
            //.fixedSize(horizontal: false, vertical: true)
            //.border(Color.black, width: 1)
        Text("\(i.inf)\n")
            .padding(5)
            //.multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .font(.custom("Monoid-Regular", size: 16))
            //.border(Color.black, width: 1)
        }
        .padding(5)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
struct SetupView: View {
    var body: some View {
        ZStack {
            Text("setup rules go here")
        }
        .ignoresSafeArea()
    }
}

struct ForecastView: View {
    @State private var dorng = 0
    var body: some View {
        VStack {
            ScrollView {
                //ForEach(0..<sortedforecast.count) { x in
                //    ReportListItem(i: sortedforecast[x])
                //}
                ForEach(sortedforecast) { x in
                    ReportListItem(i: x)
                }
            }
            //.frame(maxHeight: 500)
            HStack {
                Picker("", selection: $dorng, content: { // <2>
                    Text("year").tag(0) // <3>
                    Text("next").tag(1) // <4>
                })
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: dorng) { val in
                    let dr = (val == 1)
                    renderdat(dorange: dr, endd: ded!)
                    print("    sortedforecastcount is \(sortedforecast.count)\n")
                }
                //.font(.custom("Monoid-Regular", size: 10))
                .frame(width: 180, height: 70)
                /*
                Toggle("next only", isOn: $dorng)
                    .onChange(of: dorng) { val in
                        gdorng = val
                        print("\n    toggled is \(val)")
                        print("    gdorng is \(gdorng)")
                        print("    $dorng is \(dorng)")
                        renderdat(dorange: val, endd: ded!)
                        print("    sortedforecastcount is \(sortedforecast.count)\n")
                    }
                    .frame(width: 120)
                    .padding(5)
                */
                Text("count = \(sortedforecast.count)")
            }
            .padding(5)
            .frame(maxWidth: .infinity, maxHeight: 80, alignment: .leading)
            //.background(Color.red)
            .font(.custom("Monoid-Regular", size: 16))
        }
        .onAppear {
            dorng = 0
            print("forecastview: gdorng is \(gdorng)")
        }
    }
}


struct ContentView: View {
    var body: some View {
        TabView{
            ForecastView()
                .tabItem {
                    Text("Forecast")
                }
            SetupView()
                .tabItem {
                    Text("Setup")
                }
        }
        .onAppear {
            //print("tab-view is appearing...")
            //print("now is.............. \(date)")
            //print("one year from now is \(ded!)")
            loaddat()
            renderdat(dorange: gdorng, endd: ded!)
            print("gdorng is \(gdorng)")
        }
        //.frame(height: 1000)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
    
}


