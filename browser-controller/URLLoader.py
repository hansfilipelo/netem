#!/usr/bin/env python3

import time
import PageLoader
import selenium.webdriver
import threading

# Description: One UAController per user agent. Start and stop threads which gets content of webpages.
# If an element of the webpage can't load (happens) loading of the webpage hangs the thread.
# By having a thread controlling the flow and one loading, we can kill
# pages that does not load, preventing the test from hanging


class URLLoader(threading.Thread):

    def __init__(self, base_url, url_list, timeout, max_retries, statistics_file, use_quic=False, headless=True, debug=False):
        self.max_retries = max_retries
        self.timeout = timeout
        self.url_list = url_list
        self.base_url = base_url
        self.statistics_file = statistics_file
        self.use_quic = use_quic
        self.headless = headless
        self.debug = debug

        # Initialize Chromium/Opera
        self.chromium_options = selenium.webdriver.chrome.options.Options()
        self.chromium_options.add_argument("--ignore-certificate-errors")
        self.chromium_options.add_argument('--disable-application-cache')
        if use_quic:
            self.chromium_options.add_argument("--origin-to-force-quic-on=" +
                                               base_url +
                                               ":443")
            self.chromium_options.add_argument("--enable-quic")
        self.driver = None

        threading.Thread.__init__(self)
        self.setDaemon(True)

    def reset_driver(self):
        if self.driver:
            try:
                self.driver.quit()
            except Exception as e:
                print("Can't close non-working driver:")
                print(type(e).__name__ + str(e))
        self.driver = selenium.webdriver.Chrome(chrome_options=self.chromium_options)
        self.driver.implicitly_wait(max(self.timeout - 10, 10))
        # Does not work in S2L,
        self.driver.set_page_load_timeout(self.timeout)
        # see https://github.com/robotframework/Selenium2Library issue 575 and 532

    def load_page(self, url):
        loader = PageLoader.PageLoader(self.driver, url)
        loader.start()
        return loader

    def wait_for_page_load(self, loader):
        # This function is part of work-around mentioned in reset_driver
        t = 0
        while not loader.done.is_set():
            if t >= self.timeout:
                return False
            time.sleep(1)
            t = t + 1
        return True

    def run(self):
        self.reset_driver()

        for url in self.url_list:
            url = url.strip()
            tries = 0
            succeeded = True

            while tries < self.max_retries:
                if not succeeded:
                    self.reset_driver()

                if self.debug:
                    input("Press enter to continue...")
                loader = self.load_page("https://" + self.base_url + "/" + url)
                succeeded = self.wait_for_page_load(loader)
                results = loader.get_result()

                if succeeded and results["load_succeeded"]:
                    # Save some statistics
                    time_to_fetch_resources = results["response_end"] - results["connect_start"]
                    time_to_load_page = results["load_event_end"] - results["connect_start"]
                    statistics_line = str(url) +\
                        "   " +\
                        str(time_to_fetch_resources) +\
                        "   " +\
                        str(time_to_load_page) +\
                        "\n"
                    with open(self.statistics_file, "a") as log_file:
                        log_file.write(statistics_line)
                    break

                elif tries < self.max_retries - 1:
                    tries = tries + 1
                    statistics_line = str(url) +\
                        "   " +\
                        "Inf" +\
                        "   " +\
                        "Inf" +\
                        "\n"
                    with open(self.statistics_file, "a") as log_file:
                        log_file.write(statistics_line)
                else:
                    statistics_line = str(url) +\
                        "   " +\
                        "Inf" +\
                        "   " +\
                        "Inf" +\
                        "\n"
                    with open(self.statistics_file, "a") as log_file:
                        log_file.write(statistics_line)
                    break

        self.driver.close()
        self.driver.quit()
