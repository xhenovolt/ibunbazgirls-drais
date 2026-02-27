"use client";
import React, { useState, useRef } from 'react';
import { Dialog, Transition } from '@headlessui/react';
import { Fragment } from 'react';
import { X, Upload, FileText, AlertCircle, CheckCircle, Download, FileSpreadsheet } from 'lucide-react';
import { toast } from 'react-hot-toast';

interface ImportModalProps {
  open: boolean;
  onClose: () => void;
  onImportSuccess?: () => void;
}

export const ImportModal: React.FC<ImportModalProps> = ({
  open,
  onClose,
  onImportSuccess
}) => {
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [importing, setImporting] = useState(false);
  const [results, setResults] = useState<any>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleFileSelect = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      // Validate file type
      const allowedTypes = [
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'application/vnd.ms-excel',
        'text/csv'
      ];
      
      if (!allowedTypes.includes(file.type)) {
        toast.error('Please select an Excel (.xlsx, .xls) or CSV file');
        return;
      }
      
      setSelectedFile(file);
      setResults(null);
    }
  };

  const handleImport = async () => {
    if (!selectedFile) {
      toast.error('Please select a file to import');
      return;
    }

    setImporting(true);

    try {
      const formData = new FormData();
      formData.append('file', selectedFile);

      const response = await fetch('/api/students/import', {
        method: 'POST',
        body: formData
      });

      const result = await response.json();

      if (result.success) {
        setResults(result.data);
        toast.success(result.message);
        if (onImportSuccess) {
          onImportSuccess();
        }
      } else {
        toast.error(result.error || 'Import failed');
      }
    } catch (error: any) {
      console.error('Import error:', error);
      toast.error('An error occurred during import');
    } finally {
      setImporting(false);
    }
  };

  const downloadTemplate = () => {
    const csvContent = `First Name,Last Name,Other Name,Gender,Date of Birth,Phone,Email,Address,Class,Stream,Village,Status
John,Doe,Middle,M,1990-01-01,+256700000000,john@example.com,123 Main St,Form 1,A,Kampala,active
Jane,Smith,,F,1991-02-01,+256700000001,jane@example.com,456 Oak Ave,Form 2,B,Entebbe,active
Alice,Johnson,,F,2005-03-15,+256700000002,,Hoima District,Form 3,A,Hoima,active`;

    const blob = new Blob([csvContent], { type: 'text/csv' });
    const url = window.URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = 'students_import_template.csv';
    document.body.appendChild(link);
    link.click();
    link.remove();
    window.URL.revokeObjectURL(url);
    
    toast.success('Template downloaded successfully');
  };

  const resetModal = () => {
    setSelectedFile(null);
    setResults(null);
    if (fileInputRef.current) {
      fileInputRef.current.value = '';
    }
  };

  const handleClose = () => {
    if (importing) return;
    resetModal();
    onClose();
  };

  return (
    <Transition show={open} as={Fragment}>
      <Dialog as="div" className="relative z-50" onClose={handleClose}>
        <Transition.Child
          as={Fragment}
          enter="ease-out duration-300"
          enterFrom="opacity-0"
          enterTo="opacity-100"
          leave="ease-in duration-200"
          leaveFrom="opacity-100"
          leaveTo="opacity-0"
        >
          <div className="fixed inset-0 bg-black/50" />
        </Transition.Child>

        <div className="fixed inset-0 overflow-y-auto">
          <div className="flex min-h-full items-center justify-center p-4 text-center">
            <Transition.Child
              as={Fragment}
              enter="ease-out duration-300"
              enterFrom="opacity-0 scale-95"
              enterTo="opacity-100 scale-100"
              leave="ease-in duration-200"
              leaveFrom="opacity-100 scale-100"
              leaveTo="opacity-0 scale-95"
            >
              <Dialog.Panel className="w-full max-w-2xl transform overflow-hidden rounded-2xl bg-white dark:bg-slate-800 p-6 text-left align-middle shadow-xl transition-all">
                <div className="flex items-center justify-between mb-6">
                  <Dialog.Title className="text-lg font-semibold text-gray-900 dark:text-gray-100 flex items-center gap-2">
                    <Upload className="w-5 h-5" />
                    Import Students
                  </Dialog.Title>
                  <button
                    onClick={handleClose}
                    className="p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-slate-700 transition-colors"
                  >
                    <X className="w-5 h-5 text-gray-500" />
                  </button>
                </div>

                {!results ? (
                  <div className="space-y-6">
                    {/* Instructions */}
                    <div className="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-4">
                      <h3 className="font-medium text-blue-900 dark:text-blue-100 mb-2">Import Instructions</h3>
                      <ul className="text-sm text-blue-800 dark:text-blue-200 space-y-1">
                        <li>✓ <strong>Supported formats:</strong> Excel (.xlsx, .xls) and CSV files</li>
                        <li>✓ <strong>Required columns:</strong> First Name, Last Name</li>
                        <li>✓ <strong>Optional columns:</strong> Other Name, Gender (M/F), Date of Birth (YYYY-MM-DD), Phone, Email, Address, Class, Stream, Village, Status</li>
                        <li>✓ <strong>Simple import:</strong> Just provide first and last names to auto-admit students</li>
                        <li>✓ <strong>Status values:</strong> active, suspended, on_leave, dropped_out, at_home, sick, expelled</li>
                      </ul>
                    </div>

                    {/* Template Download */}
                    <div className="flex justify-center">
                      <button
                        onClick={downloadTemplate}
                        className="flex items-center gap-2 px-4 py-2 bg-green-500 text-white rounded-lg hover:bg-green-600 transition-colors"
                      >
                        <Download className="w-4 h-4" />
                        Download Template
                      </button>
                    </div>

                    {/* File Selection */}
                    <div className="border-2 border-dashed border-gray-300 dark:border-gray-600 rounded-lg p-8 text-center">
                      <input
                        ref={fileInputRef}
                        type="file"
                        accept=".xlsx,.xls,.csv"
                        onChange={handleFileSelect}
                        className="hidden"
                        id="file-upload"
                      />
                      <label
                        htmlFor="file-upload"
                        className="cursor-pointer flex flex-col items-center space-y-4"
                      >
                        <FileSpreadsheet className="w-12 h-12 text-gray-400" />
                        <div>
                          <span className="text-blue-600 hover:text-blue-500 font-medium">
                            Click to upload
                          </span>
                          <span className="text-gray-600 dark:text-gray-400"> or drag and drop</span>
                        </div>
                        <p className="text-sm text-gray-500">Excel (.xlsx, .xls) or CSV files only</p>
                      </label>
                    </div>

                    {selectedFile && (
                      <div className="bg-gray-50 dark:bg-slate-700 rounded-lg p-4">
                        <div className="flex items-center justify-between">
                          <div className="flex items-center gap-3">
                            <FileText className="w-5 h-5 text-blue-500" />
                            <div>
                              <p className="font-medium text-gray-900 dark:text-gray-100">
                                {selectedFile.name}
                              </p>
                              <p className="text-sm text-gray-600 dark:text-gray-400">
                                {(selectedFile.size / 1024 / 1024).toFixed(2)} MB
                              </p>
                            </div>
                          </div>
                          <button
                            onClick={() => {
                              setSelectedFile(null);
                              if (fileInputRef.current) {
                                fileInputRef.current.value = '';
                              }
                            }}
                            className="text-red-500 hover:text-red-600"
                          >
                            <X className="w-4 h-4" />
                          </button>
                        </div>
                      </div>
                    )}

                    {/* Import Button */}
                    <div className="flex justify-end space-x-3">
                      <button
                        onClick={handleClose}
                        className="px-4 py-2 text-gray-700 dark:text-gray-300 bg-gray-200 dark:bg-slate-600 rounded-lg hover:bg-gray-300 dark:hover:bg-slate-500 transition-colors"
                      >
                        Cancel
                      </button>
                      <button
                        onClick={handleImport}
                        disabled={!selectedFile || importing}
                        className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors flex items-center gap-2"
                      >
                        {importing ? (
                          <>
                            <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                            Importing...
                          </>
                        ) : (
                          <>
                            <Upload className="w-4 h-4" />
                            Import Students
                          </>
                        )}
                      </button>
                    </div>
                  </div>
                ) : (
                  /* Results Display */
                  <div className="space-y-6">
                    <div className="text-center">
                      <div className="w-16 h-16 mx-auto mb-4 rounded-full bg-green-100 dark:bg-green-900/30 flex items-center justify-center">
                        <CheckCircle className="w-8 h-8 text-green-600" />
                      </div>
                      <h3 className="text-lg font-semibold text-gray-900 dark:text-gray-100">
                        Import Completed
                      </h3>
                    </div>

                    <div className="grid grid-cols-3 gap-4 text-center">
                      <div className="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-4">
                        <div className="text-2xl font-bold text-blue-600">{results.total}</div>
                        <div className="text-sm text-blue-800 dark:text-blue-200">Total Records</div>
                      </div>
                      <div className="bg-green-50 dark:bg-green-900/20 rounded-lg p-4">
                        <div className="text-2xl font-bold text-green-600">{results.successful}</div>
                        <div className="text-sm text-green-800 dark:text-green-200">Successful</div>
                      </div>
                      <div className="bg-red-50 dark:bg-red-900/20 rounded-lg p-4">
                        <div className="text-2xl font-bold text-red-600">{results.failed}</div>
                        <div className="text-sm text-red-800 dark:text-red-200">Failed</div>
                      </div>
                    </div>

                    {results.errors && results.errors.length > 0 && (
                      <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-4">
                        <h4 className="font-medium text-red-900 dark:text-red-100 mb-2 flex items-center gap-2">
                          <AlertCircle className="w-4 h-4" />
                          Errors ({results.errors.length})
                        </h4>
                        <div className="max-h-40 overflow-y-auto">
                          {results.errors.map((error: string, index: number) => (
                            <div key={index} className="text-sm text-red-800 dark:text-red-200 py-1">
                              {error}
                            </div>
                          ))}
                        </div>
                      </div>
                    )}

                    <div className="flex justify-end space-x-3">
                      <button
                        onClick={resetModal}
                        className="px-4 py-2 text-gray-700 dark:text-gray-300 bg-gray-200 dark:bg-slate-600 rounded-lg hover:bg-gray-300 dark:hover:bg-slate-500 transition-colors"
                      >
                        Import Another File
                      </button>
                      <button
                        onClick={handleClose}
                        className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
                      >
                        Close
                      </button>
                    </div>
                  </div>
                )}
              </Dialog.Panel>
            </Transition.Child>
          </div>
        </div>
      </Dialog>
    </Transition>
  );
};
