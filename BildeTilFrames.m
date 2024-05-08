function [frames, num_frames, img_bits, img] = BildeTilFrames()
    frame_size = 100;
    
    % Read image
    Bilde = load("lenag_SD.mat");   
    img = imresize(Bilde.lenag(), 0.2);
    
    % Convert Image to Bits
    img_bits = reshape(dec2bin(img(:), 8).'-'0', [], 1);
    
    % Frame Size
    %frame_size = 100; % Change this to your desired frame size
    
    % Number of Frames
    num_frames = ceil(length(img_bits)/frame_size);
    
    % Initialize frames
    frames = zeros(num_frames, frame_size);
    
    % Fill frames with image bits
    for i = 1:num_frames
        start_index = (i-1)*frame_size + 1;
        end_index = min(i*frame_size, length(img_bits));
        frames(i, 1:(end_index-start_index+1)) = img_bits(start_index:end_index);
    end
end
    



% % Convert Bits Back to Image
% img_reconstructed_bits = reshape(frames.', [], 1);
% img_reconstructed_bits = img_reconstructed_bits(1:length(img_bits));
% img_reconstructed = reshape(uint8(bin2dec(reshape(char(img_reconstructed_bits+'0'), 8, []).')), size(img));
% 
% % Display Reconstructed Image
% imshow(img_reconstructed);












% function [frames, numFrames] = BildeTilFrames()
%     frameSize = 100;
%     Bilde = load("lenag_SD.mat");
%     % original_image = Bilde.lenag(206:305, 206:305);
%     original_image = Bilde.lenag();
%     %imshow(original_image,  []);
% 
%     % Reduce image size for demonstration (adjust as needed for radio bandwidth)
%     resizedImg = imresize(original_image, 0.1);
% 
%     %imshow(resizedImg, [], InitialMagnification = 1000);
%     % Convert grayscale values to bits (assuming 1 bit per pixel for simplicity)
%     bitStream = dec2bin(resizedImg(:));
% 
%     % Flatten the string into a row vector
%     bitStream = bitStream(:);
% 
%         % Error check for frame size
%     if frameSize <= 0
%       error('Frame size must be a positive integer.');
%     end
% 
%     % Calculate number of frames
%     numFrames = numel(bitStream) / frameSize;
% 
%     % Handle non-integer number of frames (truncate extra bits)
%     bitStream = bitStream(1:floor(numFrames) * frameSize);
% 
%     % Create frames using vectorized reshape function
%     frames = (reshape(bitStream, frameSize, [])');
%     frames1 = zeros(length(frames(:,1)), length(frames(1,:)));
% 
%     for I = 1:length(frames(:,1))
%         for i = 1:length(frames(1, :))
%             %disp(frames(I, i));
%             if frames(I, i) == '1'
%                 frames1(I, i) = 1;
%             else
%                 frames1(I, i) = 0;
%             end
%         end
%     end
%     frames = frames1;
%     numFrames = floor(numFrames);
% end
    