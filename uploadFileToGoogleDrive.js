import { LightningElement, api } from 'lwc';
import callGoogleDrive3 from '@salesforce/apex/ContentVersionTriggerHandler.callGoogleDrive3';
import { RefreshEvent } from 'lightning/refresh';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class UploadFileToGoogleDrive extends LightningElement {
    @api recordId;
    fileData ;
    get acceptedFormats() {
        return ['.pdf', '.png', '.docx', '.doc', '.csv', '.xls', '.xlsx','.jpeg', '.svg', '.txt'];
    }

    // handleUpload(event){
    //     const uploadedFiles = event.detail.files;
    //     //alert('No. of files uploaded : ' + uploadedFiles.length);
    //     alert('id ii  gg '+JSON.stringify(uploadedFiles));
    //   // alert('id ii dd gg '+JSON.stringify(uploadedFiles[0].contentVersionId));
    //    callGoogleDrive3({cvId:uploadedFiles[0].contentVersionId})
    //   this.showToast();
    //    this.dispatchEvent(new RefreshEvent());
    //     //alert('id ii dd gg '+JSON.stringify(uploadedFiles[0].contentVersionId));

    // }
    showToast() {
        const event = new ShowToastEvent({
            title: 'Success',
            variant: 'Success',
            message: 'File Uploaded Successfully',
        })
        this.dispatchEvent(event);
    }

    openfileUpload(event) {
        const file = event.target.files[0]
        console.log(file    );
        var reader = new FileReader()
        reader.onload = () => {
            var base64 = reader.result.split(',')[1];
            
            this.fileData = {
                'filename': file.name,
                'base64': base64,
                'fileSize': file.size,
                'type' : file.type
            }
           console.log(this.fileData.base64);
           this.uploadToGoogleDrive(this.fileData);
        }
        reader.readAsDataURL(file)
        
    }

    decodeBase64String(b64Data, contentType, sliceSize){
        console.log(b64Data);
        const byteCharacters = atob(b64Data);
        const byteArrays = [];

        for (let offset = 0; offset < byteCharacters.length; offset += sliceSize) {
            const slice = byteCharacters.slice(offset, offset + sliceSize);

            const byteNumbers = new Array(slice.length);
            for (let i = 0; i < slice.length; i++) {
            byteNumbers[i] = slice.charCodeAt(i);
            }

            const byteArray = new Uint8Array(byteNumbers);
            byteArrays.push(byteArray);
        }
            
        const blob = new Blob(byteArrays, {type: contentType});
        return blob;
    }

    // Function to upload a file to Google Drive
    async uploadToGoogleDrive(file) {
        try {
            console.log('file: ', JSON.stringify(file));

            const key = '98066333977-5mgahichc8cavh68dgl8eul2j0l1pq8k.apps.googleusercontent.com';
            const secret = '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';
            const redirect_uri = 'https://developers.google.com/oauthplayground';
            const refreshToken = '1//04IJ7pkmdfWCYCgYIARAAGAQSNwF-L9IrlP9vkj9PZO5FKFCLHEK2pG6SHtRc1Z16YkIeXQz-BG04zBEJ0DBl2TzKd7QPv_vmeRs';
            let contentSize = file.fileSize;
            // Get Access Token
            const tokenUrl = 'https://www.googleapis.com/oauth2/v4/token';
            const tokenData = `client_id=${key}&client_secret=${secret}&refresh_token=${refreshToken}&redirect_uri=${redirect_uri}&grant_type=refresh_token`;

            const tokenResponse = await fetch(tokenUrl, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                },
                body: tokenData,
            });

            const tokenJson = await tokenResponse.json();
            const accessToken = tokenJson.access_token;
            console.log('tokenJson: ', tokenJson);

            // Initiate resumable upload session
            const uploadUrl = 'https://www.googleapis.com/upload/drive/v2/files?uploadType=resumable';
            const uploadResponse = await fetch(uploadUrl, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${accessToken}`,
                    'Content-Type': 'application/json; charset=UTF-8',
                    'X-Upload-Content-Type': file.type,
                    'X-Upload-Content-Length': file.size,
                },
                body: JSON.stringify({
                    title: file.filename,
                    mimeType: file.type,
                }),
            });

            const sessionUrl = uploadResponse.headers.get('Location');
            console.log('sessionUrl: ', sessionUrl);

            // Upload file in chunks
            const chunkSize = 36214400;
            const numberOfChunks = Math.ceil(parseInt(contentSize) / chunkSize);
            console.log('numberOfChunks: ', numberOfChunks);
            const blobDecoded = this.decodeBase64String(file.base64, file.type, 512);
            for (let i = 0; i <= numberOfChunks; i++) {
                const startByte = i * chunkSize;
                const endByte = Math.min((i + 1) * chunkSize - 1, contentSize - 1);
                const chunkBlob = file.base64.slice(startByte, endByte + 1);

                const uploadChunkResponse = await fetch(sessionUrl, {
                    method: 'PUT',
                    headers: {
                        'Authorization': `Bearer ${accessToken}`,
                        'Content-Range': `bytes ${startByte}-${endByte}/${contentSize}`,
                        'Content-Length': chunkBlob.length.toString(),
                        'Content-Type': 'application/octet-stream',
                    },
                    body: blobDecoded,
                });
                console.log('uploadChunkResponse.status -- '+uploadChunkResponse.status);
                if (uploadChunkResponse.status === 308) {
                    console.log('The upload is incomplete, continue to the next chunk');
                    continue;
                } else {
                    // Process the response (check for errors, etc.)
                    console.log('Upload Chunk Response: ', await uploadChunkResponse.text());
                }
            }

            // Complete the resumable upload session
            const completeUploadResponse = await fetch(sessionUrl, {
                method: 'PUT',
                headers: {
                    'Authorization': `Bearer ${accessToken}`,
                    'Content-Range': 'bytes */*', // Signal completion of upload
                    'Content-Type': 'application/octet-stream',
                    'Content-Length': '0',
                },
            });

            // Process the final response (check for errors, etc.)
            console.log('Complete Upload Response: ', await completeUploadResponse.text());
        } catch (error) {
            console.error('Error:', error);
        }
    }   

}