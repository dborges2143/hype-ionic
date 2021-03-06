import { browser, by, element } from "protractor";

export class DashboardPage {

    navigateTo() {
        return browser.get('/tabs/tab1')
    }

    getPageTitleText() {
        return element(by.id('dashboard-header')).getText()
    }
}