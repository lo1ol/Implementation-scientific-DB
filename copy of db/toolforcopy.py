from selenium import webdriver
from selenium.webdriver.common.keys import Keys
import string
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait as wait
from selenium.webdriver.support import expected_conditions as EC
import selenium.common.exceptions
import os
from time import sleep


###########################
download_folder = r"C:\Users\mkh19\Desktop\copy of db\Data"+"\\"
###########################


def authorization(driver):
	while True:
		try:
			if driver.find_element_by_id("top_menu_S"):
				break
		except selenium.common.exceptions.NoSuchElementException:
			pass
		try:
			wait(driver, 10).until(EC.alert_is_present())
			alert = driver.switch_to_alert()
			alert.send_keys("LOGIN" + Keys.TAB + "PASSWORD")
			alert.accept()
		except selenium.common.exceptions.TimeoutException:
			pass


def check_records(driver, start, end):
	wait(driver, 30).until(EC.visibility_of_all_elements_located((By.ID, "box")))
	driver.execute_script("document.getElementsByName('doc_no1')[0].checked = true;")
	driver.execute_script("Javascript:chgDocList('doc_no1');")
	cookie = {'name': 'doclist', 'value': '', 'path': '/', 'domain': 'bd.viniti.ru',
	          'expiry': None, 'secure': False, 'httpOnly': False}
	array = str(start)
	for i in range(start+1, end):
		array += '%3A'+str(i)
	cookie['value'] = array
	driver.delete_cookie('doclist')
	driver.add_cookie(cookie)


def reset_check(driver):
	wait(driver, 10).until(EC.element_to_be_clickable((By.XPATH, "//a[@title='Убрать маркировку документов']")))
	driver.find_element_by_xpath("//a[@title='Убрать маркировку документов']").click()


def setup_downloads(driver):
	wait(driver, 10).until(EC.element_to_be_clickable((By.XPATH, "//a[@title='Условия вывода']")))
	driver.find_element_by_xpath("//a[@title='Условия вывода']").click()

	wait(driver, 10).until(EC.element_to_be_clickable((By.NAME, "query_count")))
	for radio in driver.find_elements_by_name("query_count"):
		if radio.get_attribute("value") == "100":
			radio.click()

	wait(driver, 10).until(EC.element_to_be_clickable((By.NAME, "out_forms")))
	for radio in driver.find_elements_by_name("out_forms"):
		if radio.get_attribute("value") == "2":
			radio.click()

	wait(driver, 10).until(EC.presence_of_element_located((By.NAME, "expmode")))
	for radio in driver.find_elements_by_name("expmode"):
		if radio.get_attribute("value") == "2":
			radio.click()

	for btn in driver.find_elements_by_tag_name("input"):
		if btn.get_attribute("value") == "Изменить":
			btn.click()


def wait_for_start_download(request):
	if request not in os.listdir(r".\Data"+"\\"):
		os.mkdir(r".\Data"+"\\"+request)
	if not hasattr(wait_for_start_download, "files"):
		wait_for_start_download.files = {}
	if request not in wait_for_start_download.files:
		wait_for_start_download.files[request] = os.listdir(r".\Data"+"\\"+request)
	while wait_for_start_download.files[request] == os.listdir(r".\Data"+"\\"+request) or list(filter((lambda s: s.endswith('part')), os.listdir(r".\Data"+"\\"+request))):
		sleep(0.5)
	wait_for_start_download.files[request] = os.listdir(r".\Data"+"\\"+request)


def export(driver, request):
	wait(driver, 10).until(EC.element_to_be_clickable((By.XPATH, "//a[@title='Экспорт']")))
	driver.find_element_by_xpath("//a[@title='Экспорт']").click()
	wait(driver, 10).until(EC.alert_is_present())
	driver.switch_to_alert().accept()
	wait_for_start_download(request)
	reset_check(driver)


def get_maximum(driver):
	wait(driver, 180).until(EC.visibility_of_element_located((By.XPATH, "/html/body/table/tbody/tr/td/div[3]/table[1]/tbody/tr[2]/td/font/font/b[1]")))
	return int(driver.find_element_by_xpath("/html/body/table/tbody/tr/td/div[3]/table[1]/tbody/tr[2]/td/font/font/b[1]").text)


def download_list(driver, request):
	wait(driver, 10).until(EC.visibility_of_element_located((By.NAME, "xmlB1")))
	driver.find_element_by_xpath("//select[@name=\"xmlB1\"]/option[12]").click()
	wait(driver, 10).until(EC.visibility_of_element_located((By.NAME, "xmlB2")))
	driver.find_element_by_name("xmlB2").send_keys(request + Keys.ENTER)
	authorization(driver)
	records_per_time = 700
	start = 1
	end = start + records_per_time
	maximum = get_maximum(driver)
	global overall
	overall += maximum
	print(request, maximum, overall)
	# while end <= maximum + 1:
	# 	print(request, start, end)
	# 	check_records(driver, start, end)
	# 	export(driver, request)
	# 	start = end
	# 	end = start + records_per_time
	# else:
	# 	print(char, start, maximum + 1)
	# 	check_records(driver, start, maximum+1)
	# 	export(driver, request)

	wait(driver, 10).until(EC.visibility_of_element_located((By.XPATH, "//a[contains(text(), \"Назад к запросу\")]")))
	driver.find_element_by_xpath("//a[contains(text(), \"Назад к запросу\")]").click()
	wait(driver, 10).until(EC.visibility_of_element_located((By.XPATH, "//input[@value=\"Сброс\"]")))
	driver.find_element_by_xpath("//input[@value=\"Сброс\"]").click()


def get_firefox_profile(request):
	profile = webdriver.FirefoxProfile()
	profile.set_preference("browser.helperApps.neverAsk.saveToDisk", 'text/xml')
	profile.set_preference("browser.download.folderList", 2)
	profile.set_preference("browser.download.manager.showWhenStarting", False)
	profile.set_preference("browser.download.dir", download_folder+request)
	return profile


def download_request(request):
	driver = webdriver.Firefox(firefox_profile=get_firefox_profile(request))
	driver.get("http://bd.viniti.ru")
	assert "VINITI" in driver.title
	setup_downloads(driver)
	download_list(driver, request)
	driver.close()


if __name__ == "__main__":
	overall = 0
	for char in "01":
		download_request(char+"$")


