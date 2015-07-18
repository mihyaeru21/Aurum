// https://github.com/Quick/Quick

import Quick
import Nimble
import Aurum

class TableOfContentsSpec: QuickSpec {
    override func spec() {
        describe("these will fail") {
            context("these will pass") {
                it("can do maths") {
                    let aurum = Aurum()
                    expect(1) == 1
                }
            }
        }
    }
}
