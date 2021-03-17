import tkinter
from tkinter import filedialog

import xlrd
from xlutils.copy import copy


##打开文件
def openFile(path, i):
    sheetval_list = []
    shname = None
    wb = xlrd.open_workbook(path)
    for j in range(len(wb.sheets())):
        if j == i - 1:
            shname = wb.sheets()[i - 1]
    try:
        rows = shname.nrows
    except IndexError:
        print("没有此下标")
    else:
        for j in range(rows):
            rv = shname.row_values(j)
            sheetval_list.append(rv)
        return sheetval_list, wb


##图形化选择文件
def openFile_Ui():
    root = tkinter.Tk()
    root.withdraw()
    return filedialog.askopenfilename(title='打开模板文件', filetypes=[('Excel', '*.xls;*.xlsx')])


##图形化选择文件夹
def openFolder_Ui():
    root = tkinter.Tk()
    root.withdraw()
    return filedialog.askdirectory()


##保存文件
def savefile(wb, path, sheetval_list):
    wb_w = copy(wb)
    ws_w = wb_w.get_sheet(0)
    k = 0  # 从首行列名算起
    for ret in sheetval_list:
        for w in range(len(ret)):
            ws_w.write(k, w, ret[w])
        k = k + 1
    wb_w.save(path)
